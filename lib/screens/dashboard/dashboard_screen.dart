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
      }
      _loadAlerts();
      _startAutoRefresh();
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
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          if (dashboardProvider.isLoading) {
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
              if (authProvider.currentUser != null) {
                await dashboardProvider.refresh(authProvider.currentUser!.userId);
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final isLargeScreen = constraints.maxWidth > 800;
                final double padding = isSmallScreen ? 12.0 : 16.0;

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLargeScreen)
                        _buildLargeScreenLayout(dashboardProvider)
                      else
                        _buildMobileLayout(dashboardProvider, isSmallScreen),
                      
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

  Widget _buildMobileLayout(DashboardProvider dashboardProvider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // System Status Card
        _buildSystemStatusCard(dashboardProvider),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildUserInsightCard(dashboardProvider),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Quick Actions
        Text(
          context.l10n.quickActions,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildQuickActions(),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Weather + compact soil gauge
        _buildFullWidthSoilCard(dashboardProvider),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildWeatherCard(dashboardProvider),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Next Schedule Cycle
        Text(
          context.l10n.nextScheduleCycle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildNextScheduleCard(dashboardProvider),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Weekly Performance
        Text(
          context.l10n.weeklyPerformance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildWeeklyPerformance(dashboardProvider),
      ],
    );
  }

  Widget _buildLargeScreenLayout(DashboardProvider dashboardProvider) {
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
                  _buildSystemStatusCard(dashboardProvider),
                  const SizedBox(height: 20),
                  _buildUserInsightCard(dashboardProvider),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.quickActions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : FamingaBrandColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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
                  _buildWeatherAndGauge(dashboardProvider, true),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.nextScheduleCycle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : FamingaBrandColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildNextScheduleCard(dashboardProvider),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.weeklyPerformance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildWeeklyPerformance(dashboardProvider),
      ],
    );
  }

  Widget _buildWeatherAndGauge(DashboardProvider dashboardProvider, bool isWideScreen) {
    final avg = dashboardProvider.avgSoilMoisture;
    final daily = dashboardProvider.dailyWaterUsage;

    Widget gauge = Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 8),
          Text(
            context.l10n.soilMoisture,
            style: const TextStyle(color: FamingaBrandColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            daily > 0 ? '${daily.toStringAsFixed(2)} L today' : '--',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : FamingaBrandColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: gauge),
          const SizedBox(width: 16),
          Expanded(child: _buildWeatherCard(dashboardProvider)),
        ],
      );
    } else {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
           return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: gauge),
              const SizedBox(width: 16),
              Expanded(child: _buildWeatherCard(dashboardProvider)),
            ],
          );
        }
        return Column(
          children: [
            gauge,
            const SizedBox(height: 12),
            _buildWeatherCard(dashboardProvider),
          ],
        );
      });
    }
  }

  Widget _buildFullWidthSoilCard(DashboardProvider dashboardProvider) {
    final avg = dashboardProvider.avgSoilMoisture;
    final daily = dashboardProvider.dailyWaterUsage;

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

  Widget _buildSystemStatusCard(DashboardProvider dashboardProvider) {
    final systemMsg = dashboardProvider.systemSoilStatusSummary();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBg = isDark ? Theme.of(context).colorScheme.primaryContainer : FamingaBrandColors.darkGreen;
    IconData cardIcon = Icons.check_circle;
    if (systemMsg.contains('dry')) {
      cardBg = Colors.orange.shade700;
      cardIcon = Icons.warning_amber_outlined;
    } else if (systemMsg.contains('wet')) {
      cardBg = Colors.blue.shade700;
      cardIcon = Icons.water_drop_outlined;
    } else if (systemMsg.contains('optimal')) {
      cardBg = isDark ? Theme.of(context).colorScheme.primaryContainer : Colors.green.shade700;
      cardIcon = Icons.check_circle;
    } else if (systemMsg.contains('No soil moisture data')) {
      cardBg = Colors.grey.shade600;
      cardIcon = Icons.info_outline;
    }
    // Optionally: hide card if all no-data
    if (systemMsg.contains('No soil moisture data')) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardBg.withOpacity(0.18),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        cardIcon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                    context.l10n.systemStatus,
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  systemMsg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(cardIcon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInsightCard(DashboardProvider dashboardProvider) {
    // Greeting + short insight based on aggregated sensor data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final name = user?.firstName ?? user?.email?.split('@').first ?? 'Farmer';

    final sensors = dashboardProvider.latestSensorDataPerField;
    double totalMoisture = 0.0;
    int moistureCount = 0;
    double totalTemp = 0.0;
    int tempCount = 0;
    sensors.forEach((_, sensor) {
      try {
        if (sensor != null) {
          if (sensor.soilMoisture != null) {
            totalMoisture += sensor.soilMoisture;
            moistureCount += 1;
          }
          if (sensor.temperature != null) {
            totalTemp += sensor.temperature;
            tempCount += 1;
          }
        }
      } catch (_) {}
    });

    final double? avgMoisture = moistureCount > 0 ? totalMoisture / moistureCount : null;
    final double? avgTemp = tempCount > 0 ? totalTemp / tempCount : null;
    final dailyWater = dashboardProvider.dailyWaterUsage;

    String insight;
    String recommendation;
    final l10n = context.l10n;
    if (avgMoisture == null) {
      insight = l10n.userInsightNoData;
      recommendation = l10n.userInsightNoDataRecommendation;
    } else {
      final avgStr = avgMoisture.toStringAsFixed(0);
      if (avgMoisture < 40) {
        insight = l10n.userInsightDryInsight(avgStr);
        recommendation = l10n.userInsightDryRecommendation;
      } else if (avgMoisture > 80) {
        insight = l10n.userInsightWetInsight(avgStr);
        recommendation = l10n.userInsightWetRecommendation;
      } else {
        insight = l10n.userInsightOptimalInsight(avgStr);
        recommendation = l10n.userInsightOptimalRecommendation;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Row(
        children: [
          // Small user avatar (soil gauge moved next to weather)
          CircleAvatar(
            backgroundColor: FamingaBrandColors.primaryOrange,
            radius: 22,
            child: Text(
              user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: FamingaBrandColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.userInsightGreeting(name),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Narrative farm-level insight
                Builder(builder: (ctx) {
                  final farmCount = dashboardProvider.fields.length;
                  final avgMoistureStr = avgMoisture != null ? '${avgMoisture.toStringAsFixed(0)}%' : 'no data';
                  final avgTempStr = avgTemp != null ? '${avgTemp.toStringAsFixed(1)}°C' : 'no data';
                  final dailyWaterStr = dailyWater > 0 ? '${dailyWater.toStringAsFixed(2)} L' : 'no data';

                  final headline = farmCount > 0
                      ? 'Across $farmCount field${farmCount > 1 ? 's' : ''}, average soil moisture is $avgMoistureStr and average temperature is $avgTempStr.'
                      : 'You have no fields yet — add a field to start receiving insights.';

                  final waterLine = farmCount > 0
                      ? 'Today you have irrigated $dailyWaterStr across your fields.'
                      : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          color: FamingaBrandColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (waterLine.isNotEmpty) const SizedBox(height: 6),
                      if (waterLine.isNotEmpty)
                        Text(
                          waterLine,
                          style: const TextStyle(
                            color: FamingaBrandColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // AI Recommendation Badge (standalone widget)
                Builder(builder: (ctx) {
                  final selectedFieldId = dashboardProvider.selectedFarmId;
                  final latestReading = dashboardProvider.latestSensorDataPerField[selectedFieldId];
                  final weather = dashboardProvider.weatherData;
                  final hasSensor = latestReading != null;
                  final hasWeather = weather != null;

                  if (!hasSensor || !hasWeather) return const SizedBox.shrink();

                  final soilMoisture = (latestReading?.soilMoisture ?? 0.0).toDouble();
                  final temperature = (weather?.temperature ?? 0.0).toDouble();
                  final humidity = (weather?.humidity ?? 0).toDouble();
                  // cropType is optional in the provider; fall back to 'unknown'
                  final cropType = 'unknown';

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AIRecommendationBadge(
                      userId: authProvider.currentUser?.userId ?? '',
                      fieldId: selectedFieldId,
                      soilMoisture: soilMoisture,
                      temperature: temperature,
                      humidity: humidity,
                      cropType: cropType,
                      onRecommendationReceived: () {
                        dev.log('📊 AI recommendation received and displayed for field: $selectedFieldId');
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.fields),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FamingaBrandColors.primaryOrange,
                ),
                child: Text(l10n.userInsightViewFields),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Get.toNamed(AppRoutes.sensors),
                child: Text(l10n.userInsightViewSensors),
              ),
            ],
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

  Widget _buildWeatherCard(DashboardProvider dashboardProvider) {
    final forecast = dashboardProvider.forecast5Day;
    
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
                  '${dashboardProvider.weeklyWaterUsage.round()}',
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
                  dashboardProvider.weeklySavings.round().toStringAsFixed(0),
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
