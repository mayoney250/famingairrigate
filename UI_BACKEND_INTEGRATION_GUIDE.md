# 🎨 UI-Backend Integration Guide

## Complete Integration Examples

### 📱 Dashboard Screen Integration

Your dashboard screen needs to display real-time data from Firebase. Here's how to integrate it:

#### Step 1: Update Dashboard Provider

Create or update `lib/providers/dashboard_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sensor_data_service.dart';
import '../services/alert_service.dart';
import '../services/weather_service.dart';
import '../services/irrigation_zone_service.dart';
import '../models/sensor_data_model.dart';
import '../models/alert_model.dart';
import '../models/weather_data_model.dart';
import '../models/irrigation_zone_model.dart';

class DashboardProvider extends ChangeNotifier {
  final SensorDataService _sensorService = SensorDataService();
  final AlertService _alertService = AlertService();
  final WeatherService _weatherService = WeatherService();
  final IrrigationZoneService _zoneService = IrrigationZoneService();

  SensorDataModel? _currentSensorData;
  WeatherDataModel? _currentWeather;
  List<AlertModel> _recentAlerts = [];
  List<IrrigationZoneModel> _zones = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  SensorDataModel? get currentSensorData => _currentSensorData;
  WeatherDataModel? get currentWeather => _currentWeather;
  List<AlertModel> get recentAlerts => _recentAlerts;
  List<IrrigationZoneModel> get zones => _zones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  // Load all dashboard data
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load sensor data (using first field for demo)
      _currentSensorData = await _sensorService.getLatestReading(
        userId,
        'field_1', // Replace with actual field ID
      );

      // Load weather
      _currentWeather = await _weatherService.getTodayWeather(userId);

      // Load alerts
      _recentAlerts = await _alertService.getUserAlerts(userId);
      _recentAlerts = _recentAlerts.take(5).toList();

      // Load zones
      _zones = await _zoneService.getUserZones(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Real-time sensor stream
  Stream<SensorDataModel?> get sensorDataStream =>
      _sensorService.streamLatestReading(userId, 'field_1');

  // Real-time alerts stream
  Stream<List<AlertModel>> get alertsStream =>
      _alertService.streamUserAlerts(userId);

  // Get irrigation status
  bool get isAnyZoneActive => _zones.any((z) => z.isActive);
}
```

#### Step 2: Update Dashboard Screen UI

Update your `dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    Future.microtask(() =>
        Provider.of<DashboardProvider>(context, listen: false)
            .loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, _) {
          if (dashboard.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboard.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${dashboard.error}'),
                  ElevatedButton(
                    onPressed: () => dashboard.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => dashboard.loadDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Card
                    _buildWeatherCard(dashboard),
                    const SizedBox(height: 16),
                    
                    // Sensor Data Cards
                    _buildSensorDataRow(dashboard),
                    const SizedBox(height: 16),
                    
                    // Irrigation Status
                    _buildIrrigationStatus(dashboard),
                    const SizedBox(height: 16),
                    
                    // Recent Alerts
                    _buildRecentAlerts(dashboard),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(DashboardProvider dashboard) {
    final weather = dashboard.currentWeather;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4D31), Color(0xFF3D6341)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Weather',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                weather?.weatherIcon ?? '☁️',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather?.temperatureDisplay ?? '-- °C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weather?.condition ?? 'No data',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${weather?.location ?? 'Unknown'} • Humidity: ${weather?.humidity.toStringAsFixed(0) ?? '--'}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataRow(DashboardProvider dashboard) {
    final sensor = dashboard.currentSensorData;
    
    return Row(
      children: [
        Expanded(
          child: _buildSensorCard(
            'Soil Moisture',
            '${sensor?.soilMoisture.toStringAsFixed(0) ?? '--'}%',
            Icons.water_drop,
            FamingaBrandColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSensorCard(
            'Temperature',
            '${sensor?.temperature.toStringAsFixed(1) ?? '--'}°C',
            Icons.thermostat,
            FamingaBrandColors.darkGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationStatus(DashboardProvider dashboard) {
    final isActive = dashboard.isAnyZoneActive;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.water,
            color: isActive ? FamingaBrandColors.primaryOrange : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Irrigation Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? 'Active' : 'All Systems Idle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? FamingaBrandColors.accentGreen
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? FamingaBrandColors.accentGreen
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'ON' : 'OFF',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(DashboardProvider dashboard) {
    if (dashboard.recentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to alerts screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dashboard.recentAlerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color getBgColor() {
      switch (alert.severity) {
        case AlertSeverity.critical:
          return Colors.red[50]!;
        case AlertSeverity.warning:
          return Colors.orange[50]!;
        default:
          return Colors.blue[50]!;
      }
    }

    Color getIconColor() {
      switch (alert.severity) {
        case AlertSeverity.critical:
          return Colors.red;
        case AlertSeverity.warning:
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    IconData getIcon() {
      switch (alert.type) {
        case AlertType.lowMoisture:
          return Icons.water_drop;
        case AlertType.highTemperature:
          return Icons.thermostat;
        case AlertType.irrigationCompleted:
          return Icons.check_circle;
        default:
          return Icons.notifications;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getBgColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(getIcon(), color: getIconColor(), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert.timeAgo,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 🔄 Irrigation Control Screen Integration

#### Create Irrigation Control Provider

Create `lib/providers/irrigation_control_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/irrigation_zone_service.dart';
import '../services/irrigation_log_service.dart';
import '../services/alert_service.dart';
import '../models/irrigation_zone_model.dart';

class IrrigationControlProvider extends ChangeNotifier {
  final IrrigationZoneService _zoneService = IrrigationZoneService();
  final IrrigationLogService _logService = IrrigationLogService();
  final AlertService _alertService = AlertService();

  List<IrrigationZoneModel> _zones = [];
  String? _selectedZoneId;
  int _durationMinutes = 30;
  bool _isIrrigating = false;
  DateTime? _irrigationStartTime;
  double _todayUsage = 0;
  double _weekUsage = 0;

  // Getters
  List<IrrigationZoneModel> get zones => _zones;
  String? get selectedZoneId => _selectedZoneId;
  int get durationMinutes => _durationMinutes;
  bool get isIrrigating => _isIrrigating;
  double get todayUsage => _todayUsage;
  double get weekUsage => _weekUsage;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  IrrigationZoneModel? get selectedZone =>
      _zones.firstWhere((z) => z.id == _selectedZoneId, orElse: () => _zones.first);

  Future<void> loadZones() async {
    _zones = await _zoneService.getUserZones(userId);
    if (_zones.isNotEmpty && _selectedZoneId == null) {
      _selectedZoneId = _zones.first.id;
    }
    await loadWaterUsage();
    notifyListeners();
  }

  Future<void> loadWaterUsage() async {
    _todayUsage = await _logService.getTodayWaterUsage(userId);
    _weekUsage = await _logService.getThisWeekWaterUsage(userId);
    notifyListeners();
  }

  void selectZone(String zoneId) {
    _selectedZoneId = zoneId;
    notifyListeners();
  }

  void setDuration(int minutes) {
    _durationMinutes = minutes;
    notifyListeners();
  }

  Future<void> startIrrigation() async {
    if (_selectedZoneId == null) return;

    _isIrrigating = true;
    _irrigationStartTime = DateTime.now();
    notifyListeners();

    // Log start
    await _logService.logIrrigationStart(
      userId,
      _selectedZoneId!,
      selectedZone!.name,
      triggeredBy: 'manual',
    );

    // Simulate irrigation (in real app, this would be controlled by IoT)
    await Future.delayed(Duration(minutes: _durationMinutes));

    // Complete irrigation
    await stopIrrigation();
  }

  Future<void> stopIrrigation() async {
    if (!_isIrrigating || _selectedZoneId == null) return;

    _isIrrigating = false;
    
    // Calculate water used (example: 50L per minute per hectare)
    final waterUsed = _durationMinutes * 50 * (selectedZone?.areaHectares ?? 1);

    // Log completion
    await _logService.logIrrigationCompleted(
      userId,
      _selectedZoneId!,
      selectedZone!.name,
      _durationMinutes,
      waterUsed,
      triggeredBy: 'manual',
    );

    // Update zone water usage
    await _zoneService.updateWaterUsage(_selectedZoneId!, waterUsed);
    await _zoneService.updateLastIrrigation(_selectedZoneId!, DateTime.now());

    // Create alert
    await _alertService.createIrrigationCompletedAlert(
      userId,
      _selectedZoneId!,
      selectedZone!.name,
    );

    // Reload data
    await loadZones();
    
    notifyListeners();
  }
}
```

---

### 📅 Schedules Screen Integration

Create a provider for schedules:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/irrigation_schedule_service.dart';
import '../services/irrigation_zone_service.dart';
import '../models/irrigation_schedule_model.dart';
import '../models/irrigation_zone_model.dart';

class SchedulesProvider extends ChangeNotifier {
  final IrrigationScheduleService _scheduleService = IrrigationScheduleService();
  final IrrigationZoneService _zoneService = IrrigationZoneService();

  List<IrrigationScheduleModel> _schedules = [];
  List<IrrigationZoneModel> _zones = [];
  bool _isLoading = false;

  List<IrrigationScheduleModel> get schedules => _schedules;
  List<IrrigationZoneModel> get zones => _zones;
  bool get isLoading => _isLoading;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<IrrigationScheduleModel>> get schedulesStream =>
      _scheduleService.streamUserSchedules(userId);

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();

    _schedules = await _scheduleService.getUserSchedules(userId);
    _zones = await _zoneService.getUserZones(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSchedule(IrrigationScheduleModel schedule) async {
    await _scheduleService.createSchedule(schedule);
    await loadSchedules();
  }

  Future<void> toggleSchedule(String scheduleId, bool isActive) async {
    await _scheduleService.toggleScheduleStatus(scheduleId, isActive);
    await loadSchedules();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _scheduleService.deleteSchedule(scheduleId);
    await loadSchedules();
  }
}
```

---

## 🔗 Update Main.dart

Update your `main.dart` to include all providers:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/irrigation_control_provider.dart';
import 'providers/schedules_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationControlProvider()),
        ChangeNotifierProvider(create: (_) => SchedulesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return GetMaterialApp(
            title: 'Faminga Irrigation',
            theme: themeProvider.currentTheme,
            initialRoute: AppRoutes.splash,
            getPages: AppRoutes.routes,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
```

---

## ✅ Integration Checklist

- [ ] All providers created
- [ ] Providers added to main.dart
- [ ] Dashboard loads real data
- [ ] Irrigation control works
- [ ] Schedules CRUD operations work
- [ ] Real-time updates function
- [ ] Error handling implemented
- [ ] Loading states shown
- [ ] Pull-to-refresh works

---

## 🎯 Next Steps

1. **Test the Dashboard:** Open app and verify all data loads
2. **Test Irrigation Control:** Start/stop irrigation and check logs
3. **Test Schedules:** Create, edit, delete schedules
4. **Verify Firebase:** Check all data in Firebase Console
5. **Test Real-time Updates:** Open app in 2 devices, make changes
6. **Error Testing:** Turn off internet, verify error messages

Your UI is now fully connected to Firebase backend! 🎉

