import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/irrigation_schedule_model.dart';
import '../models/weather_model.dart';
import '../services/irrigation_service.dart';
import '../services/sensor_service.dart';
import '../services/weather_service.dart';
import '../services/error_service.dart';
import '../services/irrigation_status_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sensor_data_model.dart';
import '../services/sensor_data_service.dart';
import '../models/flow_meter_model.dart';
import '../services/flow_meter_service.dart';
import '../models/irrigation_log_model.dart';
import '../services/irrigation_log_service.dart';
import 'dart:async';
import 'dart:developer' as dev;
import '../services/irrigation_ai_service.dart';
import '../models/ai_recommendation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/stream_debounce.dart';

class DashboardProvider with ChangeNotifier {
  final IrrigationService _irrigationService = IrrigationService();
  final SensorService _sensorService = SensorService();
  final WeatherService _weatherService = WeatherService();
  final IrrigationStatusService _statusService = IrrigationStatusService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IrrigationLogService _irrigationLogService = IrrigationLogService();

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  
  // Dashboard data
  List<IrrigationScheduleModel> _upcoming = <IrrigationScheduleModel>[];
  WeatherData? _weatherData;
  List<Map<String, dynamic>> _forecast5Day = [];
  double? _avgSoilMoisture; // Add field
  double _weeklyWaterUsage = 0.0;
  double _dailyWaterUsage = 0.0;
  double _weeklySavings = 0.0;
  String _selectedFarmId = 'farm1'; // Will be replaced by first field id
  List<Map<String, String>> _fields = <Map<String, String>>[]; // [{id, name, crop}]
  Map<String, AIRecommendation> _aiRecommendations = {}; // Cache per field
  
  // USB Sensor Data - Changed to support multiple sensors
  Map<String, Map<String, dynamic>> _usbSensorsData = {};  // Map of hardwareId -> sensor data
  Map<String, AIRecommendation> _usbAiRecommendations = {};  // Map of hardwareId -> AI recommendation
  StreamSubscription<QuerySnapshot>? _usbSensorSubscription;

  Map<String, Map<String, dynamic>> get usbSensorsData => _usbSensorsData;
  Map<String, AIRecommendation> get usbAiRecommendations => _usbAiRecommendations;
  
  Map<String, AIRecommendation> get aiRecommendations => _aiRecommendations;

  // Add location fields to DashboardProvider
  double? _latitude;
  double? _longitude;
  Box? _weatherBox;

  setLocation(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
    notifyListeners();
  }
  
  Future<void> initWeatherCache() async {
    try {
      _weatherBox ??= await Hive.openBox('weather');
      await _loadCachedWeather();
    } catch (e) {
      dev.log('Error opening weather cache: $e');
    }
  }
  
  Future<void> _loadCachedWeather() async {
    try {
      final cached = _weatherBox?.get('current_weather') as Map?;
      if (cached != null) {
        final ts = DateTime.fromMillisecondsSinceEpoch(cached['ts'] as int);
        if (DateTime.now().difference(ts) <= const Duration(hours: 3)) {
          _weatherData = WeatherData.fromMap(Map<String, dynamic>.from(cached['data'] as Map));
          _latitude = cached['lat'] as double?;
          _longitude = cached['lon'] as double?;
          notifyListeners();
          dev.log('Loaded cached weather: ${_weatherData?.location}');
        }
      }
    } catch (e) {
      dev.log('Error loading cached weather: $e');
    }
  }
  
  Future<void> setLocationFromDevice() async {
    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) {
        dev.log('Location services disabled');
        return;
      }
      
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          dev.log('Location permission denied');
          return;
        }
      }
      
      if (perm == LocationPermission.deniedForever) {
        dev.log('Location permission permanently denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      setLocation(pos.latitude, pos.longitude);
      await fetchAndSetLiveWeather();
    } catch (e) {
      dev.log('GPS error: $e');
    }
  }

  Future<void> fetchAndSetLiveWeather() async {
    if (_latitude != null && _longitude != null) {
      try {
        final weather = await _weatherService.fetchCurrentWeatherFromOpenWeather(
          lat: _latitude!,
          lon: _longitude!,
          apiKey: '1bbb141391cf468601f7de322cecb11e',
        ).timeout(const Duration(seconds: 10));
        
        if (weather != null) {
          String mappedCondition;
          switch (weather.condition.toLowerCase()) {
            case 'clear':
              mappedCondition = 'sunny';
              break;
            case 'clouds':
              mappedCondition = 'cloudy';
              break;
            case 'rain':
            case 'drizzle':
              mappedCondition = 'rainy';
              break;
            case 'thunderstorm':
              mappedCondition = 'stormy';
              break;
            case 'snow':
              mappedCondition = 'snowy';
              break;
            default:
              mappedCondition = 'unknown';
          }
          
          _weatherData = WeatherData(
            temperature: weather.temperature,
            feelsLike: weather.temperature,
            humidity: weather.humidity.toInt(),
            condition: mappedCondition,
            description: weather.description,
            windSpeed: 3.5, // To improve: parse wind from current API and wire here
            pressure: 1013,
            timestamp: weather.timestamp,
            location: weather.location,
          );

          // Fetch 5-day forecast
          try {
            final forecast = await _weatherService.fetch5DayForecast(
              lat: _latitude!,
              lon: _longitude!,
              apiKey: '1bbb141391cf468601f7de322cecb11e',
            ).timeout(const Duration(seconds: 10));
            _forecast5Day = forecast;
          } catch (_) {}
          
          await _weatherBox?.put('current_weather', {
            'ts': DateTime.now().millisecondsSinceEpoch,
            'lat': _latitude,
            'lon': _longitude,
            'data': _weatherData!.toMap(),
          });
          
          notifyListeners();
          dev.log('Weather updated and cached: ${weather.location}');
        }
      } catch (e) {
        dev.log('Error fetching weather: $e - Using cached data');
      }
    }
  }

  Future<void> setWeatherLocationFromUserAddress(String? address) async {
    if (address == null || address.trim().isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setLocation(locations.first.latitude, locations.first.longitude);
        await fetchAndSetLiveWeather();
      }
    } catch (e) {
      dev.log('Failed to geocode address: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  IrrigationScheduleModel? get nextSchedule => _upcoming.isNotEmpty ? _upcoming.first : null;
  List<IrrigationScheduleModel> get upcomingSchedules => _upcoming;
  WeatherData? get weatherData => _weatherData;
  List<Map<String, dynamic>> get forecast5Day => _forecast5Day;
  double? get avgSoilMoisture => _avgSoilMoisture;
  double get weeklyWaterUsage => _weeklyWaterUsage;
  double get dailyWaterUsage => _dailyWaterUsage;
  double get weeklySavings => _weeklySavings;
  String get selectedFarmId => _selectedFarmId;
  List<Map<String, String>> get fields => _fields;

  // Get system status
  String get systemStatus {
    if (_avgSoilMoisture == null || _avgSoilMoisture! < 40) {
      return 'Attention Required';
    } else if (_avgSoilMoisture! >= 60 && _avgSoilMoisture! <= 80) {
      return 'Optimal';
    } else {
      return 'Good';
    }
  }

  // Get system status message
  String get systemStatusMessage {
    if (_weatherData == null) {
      return 'Loading weather data...';
    }

    if (systemStatus == 'Optimal') {
      return 'Everything is fully loaded. Current conditions are ideal for your crops.';
    } else if (systemStatus == 'Attention Required') {
      return 'Soil moisture is low. Consider irrigating soon.';
    } else {
      return 'System is operating normally.';
    }
  }

  // Add this helper for summarizing soil status across all fields
  String systemSoilStatusSummary() {
    // Uses same logic as the per-field card
    final sensors = latestSensorDataPerField;
    bool anyDry = false, anyWet = false, anyOptimal = false, anyData = false;
    for (final sid in fields.map((f) => f['id'])) {
      final sensor = sid != null ? sensors[sid] : null;
      if (sensor != null) {
        anyData = true;
        if (sensor.soilMoisture < 50) {
          anyDry = true;
        } else if (sensor.soilMoisture >= 100) {
          anyWet = true;
        } else {
          anyOptimal = true;
        }
      }
    }
    if (!anyData) return "No soil moisture data.";
    if (anyWet) return "Soil is too wet – check drainage.";
    if (anyDry) return "Soil is dry – it's time to irrigate.";
    return "Soil conditions are optimal – no action needed.";
  }

  // Load dashboard data
  Future<void> loadDashboardData(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load essential data first
      await Future.wait([
        _loadFields(userId).catchError((e) {
          dev.log('Error in _loadFields: $e');
          return null;
        }),
        _loadUpcoming(userId).catchError((e) {
          dev.log('Error in _loadUpcoming: $e');
          return null;
        }),
      ]);

      // Initialize USB sensor listener
      _initUsbSensorListener();

      // Defer non-critical tasks
      Future(() async {
        try {
          await Future.wait([
            _loadWeatherData().timeout(const Duration(seconds: 10)).catchError((e) {
              dev.log('Error in _loadWeatherData: $e');
              return null;
            }),
            _loadWeeklyStats(userId).timeout(const Duration(seconds: 10)).catchError((e) {
              dev.log('Error in _loadWeeklyStats: $e');
              return null;
            }),
          ]);

          await setLocationFromDevice().timeout(const Duration(seconds: 10)).catchError((e) {
            dev.log('Error in setLocationFromDevice: $e');
          });

          if (_fields.isNotEmpty) {
            subscribeToLiveFieldData(userId);
          }

          await _refreshDailySoilAverage().timeout(const Duration(seconds: 10)).catchError((e) {
            dev.log('Error in _refreshDailySoilAverage: $e');
          });
          await _refreshWeeklyWaterUsage(userId: userId).timeout(const Duration(seconds: 10)).catchError((e) {
            dev.log('Error in _refreshWeeklyWaterUsage: $e');
          });
          await _refreshDailyWaterUsage(userId: userId).timeout(const Duration(seconds: 10)).catchError((e) {
            dev.log('Error in _refreshDailyWaterUsage: $e');
          });
        } catch (e) {
          dev.log('Error in deferred tasks: $e');
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorService.toMessage(e);
      _isLoading = false;
      dev.log('Error loading dashboard data: $e');
      notifyListeners();
    }
  }

  // Load upcoming scheduled irrigations (scoped by selected farm, with legacy fallback)
  Future<void> _loadUpcoming(String userId) async {
    try {
      _irrigationService.getUserSchedules(userId).listen((all) {
        if (all == null || all.isEmpty) {
          dev.log('No schedules found for user: $userId');
          _upcoming = [];
          notifyListeners();
          return;
        }

        final now = DateTime.now();
        DateTime startFor(IrrigationScheduleModel s) => s.nextRun ?? s.startTime;
        DateTime endFor(IrrigationScheduleModel s) => startFor(s).add(Duration(minutes: s.durationMinutes));

        final filtered = all.where((s) {
          if (!s.isActive) return false;
          // Show across all fields
          if (s.status == 'scheduled') return startFor(s).isAfter(now);
          if (s.status == 'running') return endFor(s).isAfter(now);
          return false; // hide stopped/completed
        }).toList();

        filtered.sort((a, b) => startFor(a).compareTo(startFor(b)));
        _upcoming = filtered; // Assign directly to maintain type compatibility
        notifyListeners();
      }, onError: (error) {
        dev.log('Error in getUserSchedules stream: $error');
      });
    } catch (e) {
      dev.log('Error loading upcoming schedules: $e');
    }
  }

  // Load fields for the current user
  Future<void> _loadFields(String userId) async {
    try {
      if (userId.isEmpty) {
        dev.log('Invalid userId provided to _loadFields');
        _fields = [];
        notifyListeners();
        return;
      }

      final snapshot = await _firestore
          .collection('fields')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        dev.log('No fields found for user: $userId');
        _fields = [];
        notifyListeners();
        return;
      }

      _fields = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data()); // Ensure proper casting
        final label = (data['label'] ?? data['name'] ?? data['fieldName'] ?? d.id).toString();
        final crop = (data['cropType'] ?? data['crop'] ?? 'unknown').toString();
        return {'id': d.id, 'name': label, 'crop': crop};
      }).toList();

      if (_fields.isNotEmpty) {
        final stillExists = _fields.any((f) => f['id'] == _selectedFarmId);
        if (!stillExists) {
          _selectedFarmId = _fields.first['id']!;
        }
      }
    } catch (e) {
      dev.log('Error loading fields: $e');
    }
  }

  // Load weather data
  Future<void> _loadWeatherData() async {
    try {
      // Try to get today's weather from Firebase
      final weather = await _weatherService.getTodayWeather('user_id'); // Replace with actual userId
      if (weather != null) {
        // Convert WeatherDataModel to WeatherData
        _weatherData = WeatherData(
          temperature: weather.temperature,
          feelsLike: weather.temperature,
          humidity: weather.humidity.toInt(),
          condition: weather.condition.toLowerCase(),
          description: weather.description,
          windSpeed: 3.5, // Default
          pressure: 1013, // Default
          timestamp: weather.timestamp,
          location: weather.location,
        );
      } else {
        _weatherData = _getDefaultWeatherData();
      }
    } catch (e) {
      dev.log('Error loading weather data: $e');
      _weatherData = _getDefaultWeatherData();
    }
  }

  WeatherData _getDefaultWeatherData() {
    return WeatherData(
      temperature: 26.0,
      feelsLike: 28.0,
      humidity: 65,
      condition: 'sunny',
      description: 'Clear sky',
      windSpeed: 3.5,
      pressure: 1013,
      timestamp: DateTime.now(),
      location: 'Kigali',
    );
  }

  // Legacy soil moisture loader removed; we use _refreshDailySoilAverage fed by sensorData
  // Load weekly statistics
  Future<void> _loadWeeklyStats(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      _weeklyWaterUsage = await _irrigationService.getWaterUsage(
        userId,
        weekAgo,
        now,
      );

      _weeklySavings = await _irrigationService.calculateSavings(
        userId,
        weekAgo,
        now,
      );
    } catch (e) {
      dev.log('Error loading weekly stats: $e');
      // Use mock data
      _weeklyWaterUsage = 850.0;
      _weeklySavings = 1200.0;
    }
  }

  // Start irrigation manually
  Future<bool> startManualIrrigation({
    required String userId,
    required String fieldId,
    required String fieldName,
    int durationMinutes = 60,
  }) async {
    try {
      final success = await _statusService.startIrrigationManually(
        userId: userId,
        farmId: _selectedFarmId,
        fieldId: fieldId,
        fieldName: fieldName,
        durationMinutes: durationMinutes,
      );

      if (success) {
        // Reload dashboard data
        await loadDashboardData(userId);
      }

      return success;
    } catch (e) {
      dev.log('Error starting manual irrigation: $e');
      return false;
    }
  }

  // Start a specific scheduled cycle now
  Future<bool> startScheduledCycleNow(String scheduleId, String userId) async {
    try {
      final ok = await _statusService.startScheduledNow(scheduleId);
      if (ok) {
        await loadDashboardData(userId);
      }
      return ok;
    } catch (e) {
      dev.log('Error starting scheduled cycle now: $e');
      return false;
    }
  }

  // Stop a specific running/scheduled cycle
  Future<bool> stopCycle(String scheduleId, String userId) async {
    try {
      final ok = await _statusService.stopIrrigationManually(scheduleId);
      if (ok) {
        await loadDashboardData(userId);
      }
      return ok;
    } catch (e) {
      dev.log('Error stopping cycle: $e');
      return false;
    }
  }

  // Refresh dashboard
  Future<void> refresh(String userId) async {
    await loadDashboardData(userId);
  }

  // Change selected farm
  void selectFarm(String farmId) {
    if (_selectedFarmId != farmId) {
      _selectedFarmId = farmId;
      notifyListeners();
      // Re-filter upcoming for the new farm
      // Requires a user context; if none, the next loadDashboardData will set it
      // We trigger a silent re-run by calling _loadUpcoming with last-known user from an existing schedule if present
      // Otherwise, do nothing here.
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _aggTimer?.cancel();
    _usbSensorSubscription?.cancel();
    super.dispose();
  }

  // Live/streamed sensor and flow meter values
  final SensorDataService _sensorDataService = SensorDataService();
  final FlowMeterService _flowMeterService = FlowMeterService();
  final IrrigationAIService _aiService = IrrigationAIService();
  AIRecommendation? _currentAIRecommendation;
  DateTime? _lastAIRequestTime;
  bool _aiRequestInProgress = false;
  final Map<String, SensorDataModel?> _latestSensorDataPerField = {};
  final Map<String, FlowMeterModel?> _latestFlowDataPerField = {};
  String? _lastActionError;

  Map<String, SensorDataModel?> get latestSensorDataPerField => _latestSensorDataPerField;
  Map<String, FlowMeterModel?> get latestFlowDataPerField => _latestFlowDataPerField;
  String? get lastActionError => _lastActionError;
  AIRecommendation? get currentAIRecommendation => _currentAIRecommendation;
  bool get aiRequestInProgress => _aiRequestInProgress;

  Timer? _aggTimer;
  Timer? _statusTimer;
  final Map<String, bool> _sensorOfflineStatus = {}; // Track offline status per field
  String? _sensorOfflineError; // Global sensor error message

  // Getters for sensor offline status
  bool isSensorOffline(String fieldId) => _sensorOfflineStatus[fieldId] ?? false;
  String? get sensorOfflineError => _sensorOfflineError;

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfThisWeekMonday() {
    final now = DateTime.now();
    final mondayDelta = (now.weekday - DateTime.monday) % 7; // 0 if monday
    final monday = now.subtract(Duration(days: mondayDelta));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<void> _refreshDailySoilAverage() async {
    try {
      if (_fields.isEmpty) {
        dev.log('🟡 [SOIL AVG] No fields to calculate average');
        _avgSoilMoisture = null;
        return;
      }
      
      // Calculate average from current live sensor readings
      double sum = 0;
      int count = 0;
      dev.log('🟡 [SOIL AVG] Calculating average from live data for ${_fields.length} fields');
      
      for (final f in _fields) {
        final fieldId = f['id']!;
        final sensorData = _latestSensorDataPerField[fieldId];
        
        if (sensorData != null && sensorData.soilMoisture != null) {
          dev.log('🟡 [SOIL AVG] Field $fieldId: ${sensorData.soilMoisture}%');
          sum += sensorData.soilMoisture;
          count++;
        } else {
          dev.log('🟡 [SOIL AVG] Field $fieldId: No data available');
        }
      }
      
      _avgSoilMoisture = count > 0 ? sum / count : null;
      dev.log('🟡 [SOIL AVG] Final average: $_avgSoilMoisture (from $count fields with data)');
      notifyListeners();
    } catch (e) {
      dev.log('❌ [SOIL AVG] Error: $e');
    }
  }

  Future<void> _refreshWeeklyWaterUsage({String? userId}) async {
    try {
      if (_fields.isEmpty || userId == null) return;
      final start = _startOfThisWeekMonday();
      final logs = await _irrigationLogService.getLogsInRange(userId, start, DateTime.now());
      
      double total = 0;
      for (final f in _fields) {
        final fieldId = f['id']!;
        // Filter logs for this field (zoneId matches fieldId)
        final fieldLogs = logs.where((l) => l.zoneId == fieldId);
        
        for (final log in fieldLogs) {
          if (log.waterUsed != null) {
            total += log.waterUsed!;
          }
        }
      }
      _weeklyWaterUsage = total;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshDailyWaterUsage({String? userId}) async {
    try {
      if (_fields.isEmpty || userId == null) {
        dev.log('⚠️ [WATER] Cannot refresh: fields=${_fields.length}, userId=$userId');
        return;
      }
      
      dev.log('🔍 [WATER] Fetching irrigation logs for user: $userId');
      
      // Fetch recent logs (last 30 days) to show data even if no logs today
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final logs = await _irrigationLogService.getLogsInRange(userId, thirtyDaysAgo, now);
      
      dev.log('📊 [WATER] Found ${logs.length} total logs in last 30 days');
      
      double total = 0;
      int logCount = 0;
      
      for (final f in _fields) {
        final fieldId = f['id']!;
        final fieldLogs = logs.where(
          (log) => _isWaterLogValidForField(log, fieldId, userId),
        );
        dev.log('🔍 [WATER] Field $fieldId has ${fieldLogs.length} matching logs');
        
        for (final log in fieldLogs) {
          if (log.waterUsed != null) {
            dev.log('✅ [WATER] Adding ${log.waterUsed}L from log ${log.id} (${log.action}) for field $fieldId');
            total += log.waterUsed!;
            logCount++;
          } else {
            dev.log('⚠️ [WATER] Skipping log ${log.id} for $fieldId - missing waterUsed value');
          }
        }
      }
      
      dev.log('💧 [WATER] Total water usage from $logCount logs: ${total}L');
      _dailyWaterUsage = total;
      notifyListeners();
    } catch (e) {
      dev.log('❌ Error refreshing daily water usage: $e');
    }
  }

  bool _isWaterLogValidForField(
    IrrigationLogModel log,
    String fieldId,
    String userId,
  ) {
    final matchesUser = log.userId == userId;
    final logFieldId = log.zoneId;
    final matchesField = logFieldId == fieldId;
    if (!matchesUser) {
      dev.log('⚠️ [WATER] Log ${log.id} skipped - belongs to different user ${log.userId}');
      return false;
    }
    if (!matchesField) {
      dev.log('⚠️ [WATER] Log ${log.id} skipped - zone ${logFieldId} != field $fieldId');
      return false;
    }
    return true;
  }

  void _startAggTimer(String userId) {
    _aggTimer?.cancel();
    _aggTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _refreshDailySoilAverage();
      await _refreshWeeklyWaterUsage(userId: userId);
      await _refreshDailyWaterUsage(userId: userId);
    });
  }

  // Dev utility: add a test flow meter reading for a field
  Future<bool> addTestFlowUsage({
    required String userId,
    required String fieldId,
    double? liters,
  }) async {
    try {
      _lastActionError = null;
      final amount = liters ?? (5 + (DateTime.now().millisecondsSinceEpoch % 200) / 10.0); // 5.0 – 25.0-ish
      final test = FlowMeterModel(
        id: '',
        userId: userId,
        fieldId: fieldId,
        liters: amount,
        timestamp: DateTime.now(),
      );
      await _flowMeterService.createReading(test, userId: userId);

      // update local latest + aggregates
      _latestFlowDataPerField[fieldId] = test;
      await _refreshWeeklyWaterUsage(userId: userId);
      await _refreshDailyWaterUsage(userId: userId);
      notifyListeners();
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      return false;
    }
  }

  // Start/restart live listeners for all fields the user has
  void subscribeToLiveFieldData(String userId) {
    dev.log('🟢 [DASHBOARD] Subscribing to live field data for ${_fields.length} fields');
    for (var field in _fields) {
      final fieldId = field['id']!;
      dev.log('🟢 [DASHBOARD] Setting up listeners for field: $fieldId');
      
      // Prime with latest once so UI doesn't wait for stream
      _sensorDataService.getLatestReading(fieldId).then((sensorData) {
        dev.log('🟢 [DASHBOARD] Initial sensor data loaded for $fieldId: ${sensorData?.soilMoisture}');
        _latestSensorDataPerField[fieldId] = sensorData;
        _checkSensorOffline(fieldId, sensorData);
        _refreshDailySoilAverage();
        // Trigger AI recommendation fetch for this field when new latest reading is available
        _maybeFetchAIForField(fieldId);
        notifyListeners();
      }).catchError((_) {});
      
      // Sensor readings with 3-second debounce to reduce UI jank
      _sensorDataService.streamLatestReading(fieldId)
        .debounce(const Duration(seconds: 3))
        .listen((sensorData) {
        dev.log('🟢 [DASHBOARD] Stream update for $fieldId: moisture=${sensorData?.soilMoisture}, temp=${sensorData?.temperature}');
        _latestSensorDataPerField[fieldId] = sensorData;
        _checkSensorOffline(fieldId, sensorData);
        dev.log('🟢 [DASHBOARD] Updated _latestSensorDataPerField[$fieldId], calling notifyListeners()');
        // Update live aggregates quickly from latest values
        _refreshDailySoilAverage();
        // Trigger AI recommendation fetch for this field on each new reading (internal debounce will prevent excess calls)
        _maybeFetchAIForField(fieldId);
        notifyListeners();
        dev.log('🟢 [DASHBOARD] notifyListeners() called');
      });
      // Flow meter optional: ignore if collection doesn't exist
      _flowMeterService.getLatestReading(fieldId, userId: userId).then((flowData) {
        _latestFlowDataPerField[fieldId] = flowData;
        // update aggregates when latest flow reading arrives
        _refreshWeeklyWaterUsage(userId: userId);
        _refreshDailyWaterUsage(userId: userId);
        notifyListeners();
      }).catchError((_) {});
      _flowMeterService.streamLatestReading(fieldId, userId: userId)
        .debounce(const Duration(seconds: 3))
        .listen((flowData) {
        _latestFlowDataPerField[fieldId] = flowData;
        _refreshWeeklyWaterUsage(userId: userId);
        _refreshDailyWaterUsage(userId: userId);
        notifyListeners();
      }, onError: (_) {});
    }
    _startAggTimer(userId);
  }

  // Decide whether to fetch AI recommendation for a field (debounced & non-blocking)
  void _maybeFetchAIForField(String fieldId) {
    try {
      if (_aiRequestInProgress) return;
      final sensor = _latestSensorDataPerField[fieldId];
      final weather = _weatherData;
      if (sensor == null || weather == null) return;

      // Debounce: skip if last request was within 30 seconds
      if (_lastAIRequestTime != null && DateTime.now().difference(_lastAIRequestTime!).inSeconds < 30) {
        dev.log('AI: Skipping fetch for $fieldId - debounce active');
        return;
      }

      // Fire and forget
      _fetchAIRecommendation(fieldId, sensor.soilMoisture ?? 0.0, weather.temperature, weather.humidity.toDouble());
    } catch (e) {
      dev.log('AI: _maybeFetchAIForField error: $e');
    }
  }

  /// Check if sensor data is stale (older than 3 hours) or missing
  Future<void> _checkSensorOffline(String fieldId, SensorDataModel? sensorData) async {
    if (sensorData == null) {
      _sensorOfflineStatus[fieldId] = true;
      
      // Check if this field has EVER had data
      final hasHistory = await _sensorDataService.hasHistoricalData(fieldId);
      final fieldName = _fields.firstWhere((f) => f['id'] == fieldId, orElse: () => {'name': fieldId})['name'] ?? fieldId;
      
      if (hasHistory) {
        _sensorOfflineError = 'Sensor for $fieldName is not logging data. Please check connection.';
        dev.log('⚠️ [SENSOR OFFLINE] Field $fieldId has history but no current data');
      } else {
        // If no history, it's likely a configuration issue or new field
        // We might want to show a different message or no error at all depending on UX
        // For now, let's be specific
        _sensorOfflineError = 'No sensor configured for $fieldName. Please add a sensor.';
        dev.log('ℹ️ [SENSOR MISSING] Field $fieldId has no historical data');
      }
      return;
    }

    final now = DateTime.now();
    var dataAge = now.difference(sensorData.timestamp);
    
    // Handle clock skew (future timestamps)
    if (dataAge.isNegative) {
      dataAge = Duration.zero;
    }

    final isOffline = dataAge.inHours >= 3;

    _sensorOfflineStatus[fieldId] = isOffline;

    if (isOffline) {
      final hoursOld = dataAge.inHours;
      final fieldName = _fields.firstWhere((f) => f['id'] == fieldId, orElse: () => {'name': fieldId})['name'] ?? fieldId;
      _sensorOfflineError = 'Sensor for $fieldName is not logging data. Last update: $hoursOld hours ago.';
      dev.log('⚠️ [SENSOR OFFLINE] Field $fieldId ($fieldName) data is $hoursOld hours old (last update: ${sensorData.timestamp})');
    } else {
      // Clear error if data is fresh
      final offlineCount = _sensorOfflineStatus.values.where((v) => v).length;
      if (offlineCount == 0) {
        _sensorOfflineError = null;
      }
      dev.log('✅ [SENSOR ONLINE] Field $fieldId data is ${dataAge.inMinutes} minutes old');
    }
  }

  void _initUsbSensorListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      dev.log('No user logged in, skipping USB sensor listener');
      return;
    }

    _usbSensorSubscription?.cancel();
    _usbSensorSubscription = _firestore
        .collection('faminga_sensors')
        .where('userId', isEqualTo: userId)  // Filter by logged-in user
        .snapshots()
        .debounce(const Duration(seconds: 3))
        .listen((snapshot) {
      final sensors = <String, Map<String, dynamic>>{};
      
      for (var doc in snapshot.docs) {
        if (doc.exists && doc.data() != null) {
          sensors[doc.id] = doc.data();
          // Fetch AI recommendation for each sensor
          _fetchSensorAIRecommendation(doc.id, doc.data());
        }
      }
      
      _usbSensorsData = sensors;
      notifyListeners();
    }, onError: (e) {
      dev.log('Error listening to USB sensors: $e');
    });
  }

  Future<void> _fetchSensorAIRecommendation(String hardwareId, Map<String, dynamic> sensorData) async {
    if (sensorData == null || _weatherData == null) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final moisture = (sensorData['moisture'] as num?)?.toDouble() ?? 0.0;
      final temperature = (sensorData['temperature'] as num?)?.toDouble() ?? 0.0;
      final fieldId = sensorData['fieldId'] as String? ?? 'unknown';
      
      final rec = await _aiService.getIrrigationAdvice(
        userId: userId,
        fieldId: fieldId,
        soilMoisture: moisture,
        temperature: temperature,
        humidity: _weatherData!.humidity.toDouble(),
        cropType: 'General',
      );

      _usbAiRecommendations[hardwareId] = rec;
      notifyListeners();
    } catch (e) {
      dev.log('Error fetching AI for sensor $hardwareId: $e');
    }
  }

  Future<void> _fetchAIRecommendation(String fieldId, double soilMoisture, double temperature, double humidity) async {
    if (_aiRequestInProgress) return;
    _aiRequestInProgress = true;
    notifyListeners();
    _lastAIRequestTime = DateTime.now();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // Find crop type for this field
      final field = _fields.firstWhere((f) => f['id'] == fieldId, orElse: () => {'crop': 'unknown'});
      final cropType = field['crop'] ?? 'unknown';

      final rec = await _aiService.getIrrigationAdvice(
        userId: userId,
        fieldId: fieldId,
        soilMoisture: soilMoisture,
        temperature: temperature,
        humidity: humidity,
        cropType: cropType,
      );

      _aiRecommendations[fieldId] = rec;
      notifyListeners();

      // Persist recommendation to Firestore for downstream notification processing
      await FirebaseFirestore.instance.collection('ai_recommendations').add({
        'userId': userId,
        'fieldId': fieldId,
        'recommendation': rec.recommendation,
        'reasoning': rec.reasoning,
        'confidence': rec.confidence,
        'soilMoisture': rec.soilMoisture,
        'temperature': rec.temperature,
        'humidity': rec.humidity,
        'cropType': rec.cropType,
        'timestamp': FieldValue.serverTimestamp(),
        'origin': 'client',
      });
    } catch (e, st) {
      dev.log('AI: _fetchAIRecommendation failed: $e');
      dev.log(st.toString());
    } finally {
      _aiRequestInProgress = false;
      notifyListeners();
    }
  }
}
