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
import 'dart:async';
import 'dart:developer' as dev;
import '../services/irrigation_ai_service.dart';
import '../models/ai_recommendation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardProvider with ChangeNotifier {
  final IrrigationService _irrigationService = IrrigationService();
  final SensorService _sensorService = SensorService();
  final WeatherService _weatherService = WeatherService();
  final IrrigationStatusService _statusService = IrrigationStatusService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  List<Map<String, String>> _fields = <Map<String, String>>[]; // [{id, name}]

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
        } else if (sensor.soilMoisture > 100) {
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
        return {'id': d.id, 'name': label};
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
      if (_fields.isEmpty) return;
      final start = _startOfToday();
      double sum = 0;
      int count = 0;
      for (final f in _fields) {
        final fieldId = f['id']!;
        final readings = await _sensorDataService.getReadingsInRange(fieldId, start, DateTime.now());
        if (readings.isNotEmpty) {
          // average per field in window
          final avgField = readings.map((r) => r.soilMoisture).reduce((a,b)=>a+b) / readings.length;
          sum += avgField;
          count++;
        }
      }
      _avgSoilMoisture = count > 0 ? sum / count : null;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshWeeklyWaterUsage({String? userId}) async {
    try {
      if (_fields.isEmpty) return;
      final start = _startOfThisWeekMonday();
      double total = 0;
      for (final f in _fields) {
        final fieldId = f['id']!;
        total += await _flowMeterService.getUsageSince(fieldId, start, userId: userId);
      }
      _weeklyWaterUsage = total;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshDailyWaterUsage({String? userId}) async {
    try {
      if (_fields.isEmpty) return;
      final start = _startOfToday();
      double total = 0;
      for (final f in _fields) {
        final fieldId = f['id']!;
        total += await _flowMeterService.getUsageSince(fieldId, start, userId: userId);
      }
      _dailyWaterUsage = total;
      notifyListeners();
    } catch (_) {}
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
    for (var field in _fields) {
      final fieldId = field['id']!;
      // Prime with latest once so UI doesn't wait for stream
      _sensorDataService.getLatestReading(fieldId).then((sensorData) {
        _latestSensorDataPerField[fieldId] = sensorData;
        _refreshDailySoilAverage();
        // Trigger AI recommendation fetch for this field when new latest reading is available
        _maybeFetchAIForField(fieldId);
        notifyListeners();
      }).catchError((_) {});
      // Sensor readings
      _sensorDataService.streamLatestReading(fieldId).listen((sensorData) {
        _latestSensorDataPerField[fieldId] = sensorData;
        // Update live aggregates quickly from latest values
        _refreshDailySoilAverage();
        // Trigger AI recommendation fetch for this field on each new reading (internal debounce will prevent excess calls)
        _maybeFetchAIForField(fieldId);
        notifyListeners();
      });
      // Flow meter optional: ignore if collection doesn't exist
      _flowMeterService.getLatestReading(fieldId, userId: userId).then((flowData) {
        _latestFlowDataPerField[fieldId] = flowData;
        // update aggregates when latest flow reading arrives
        _refreshWeeklyWaterUsage(userId: userId);
        _refreshDailyWaterUsage(userId: userId);
        notifyListeners();
      }).catchError((_) {});
      _flowMeterService.streamLatestReading(fieldId, userId: userId).listen((flowData) {
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

  Future<void> _fetchAIRecommendation(String fieldId, double soilMoisture, double temperature, double humidity) async {
    if (_aiRequestInProgress) return;
    _aiRequestInProgress = true;
    notifyListeners();
    _lastAIRequestTime = DateTime.now();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final cropType = 'unknown'; // TODO: replace with actual field crop type if available

      final rec = await _aiService.getIrrigationAdvice(
        userId: userId,
        fieldId: fieldId,
        soilMoisture: soilMoisture,
        temperature: temperature,
        humidity: humidity,
        cropType: cropType,
      );

      _currentAIRecommendation = rec;
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
