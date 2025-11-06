import 'dart:developer';
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
import '../models/sensor_data_model.dart';
import '../services/sensor_data_service.dart';
import '../models/flow_meter_model.dart';
import '../services/flow_meter_service.dart';
import 'dart:async';

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
  double? _avgSoilMoisture; // Add field
  double _weeklyWaterUsage = 0.0;
  double _weeklySavings = 0.0;
  String _selectedFarmId = 'farm1'; // Will be replaced by first field id
  List<Map<String, String>> _fields = <Map<String, String>>[]; // [{id, name}]

  // Add location fields to DashboardProvider
  double? _latitude;
  double? _longitude;

  setLocation(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
    notifyListeners();
  }

  Future<void> fetchAndSetLiveWeather() async {
    if (_latitude != null && _longitude != null) {
      final weather = await _weatherService.fetchCurrentWeatherFromOpenWeather(
        lat: _latitude!,
        lon: _longitude!,
        apiKey: '1bbb141391cf468601f7de322cecb11e', // User-provided key
      );
      if (weather != null) {
        _weatherData = WeatherData(
          temperature: weather.temperature,
          feelsLike: weather.temperature,
          humidity: weather.humidity.toInt(),
          condition: weather.condition.toLowerCase(),
          description: weather.description,
          windSpeed: 3.5,
          pressure: 1013,
          timestamp: weather.timestamp,
          location: weather.location,
        );
        notifyListeners();
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
      log('Failed to geocode address: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  IrrigationScheduleModel? get nextSchedule => _upcoming.isNotEmpty ? _upcoming.first : null;
  List<IrrigationScheduleModel> get upcomingSchedules => _upcoming;
  WeatherData? get weatherData => _weatherData;
  double? get avgSoilMoisture => _avgSoilMoisture;
  double get weeklyWaterUsage => _weeklyWaterUsage;
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

      // Load data in parallel, but don't let one failure stop the others
      final results = await Future.wait([
        // Sync irrigation statuses before reading
        _statusService.startDueSchedules().catchError((e) {
          log('Error in startDueSchedules: $e');
          return 0;
        }),
        _statusService.markDueIrrigationsCompleted().catchError((e) {
          log('Error in markDueIrrigationsCompleted: $e');
          return 0;
        }),
        _loadUpcoming(userId).catchError((e) {
          log('Error in _loadUpcoming: $e');
          return null;
        }),
        _loadFields(userId).catchError((e) {
          log('Error in _loadFields: $e');
          return null;
        }),
        _loadWeatherData().catchError((e) {
          log('Error in _loadWeatherData: $e');
          return null;
        }),
        // soil moisture now computed via sensorData in _refreshDailySoilAverage
        _loadWeeklyStats(userId).catchError((e) {
          log('Error in _loadWeeklyStats: $e');
          return null;
        }),
      ]);

      _isLoading = false;
      notifyListeners();
      if (_fields.isNotEmpty) {
        subscribeToLiveFieldData(userId);
      }
      await _refreshDailySoilAverage();
      await _refreshWeeklyWaterUsage();
      // Start background status sync every 60s (auto-start due + auto-complete)
      _statusTimer ??= Timer.periodic(const Duration(seconds: 60), (_) async {
        try {
          await _statusService.startDueSchedules();
          await _statusService.markDueIrrigationsCompleted();
        } catch (_) {}
      });
    } catch (e) {
      _errorMessage = ErrorService.toMessage(e);
      _isLoading = false;
      log('Error loading dashboard data: $e');
      notifyListeners();
    }
  }

  // Load upcoming scheduled irrigations (scoped by selected farm, with legacy fallback)
  Future<void> _loadUpcoming(String userId) async {
    try {
      _irrigationService.getUserSchedules(userId).listen((all) {
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
        _upcoming = filtered;
        notifyListeners();
      });
    } catch (e) {
      log('Error loading upcoming schedules: $e');
    }
  }

  // Load fields for the current user
  Future<void> _loadFields(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('fields')
          .where('userId', isEqualTo: userId)
          .get();

      _fields = snapshot.docs.map((d) {
        final data = d.data();
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
      log('Error loading fields: $e');
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
      log('Error loading weather data: $e');
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
      log('Error loading weekly stats: $e');
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
      log('Error starting manual irrigation: $e');
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
      log('Error starting scheduled cycle now: $e');
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
      log('Error stopping cycle: $e');
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
  final Map<String, SensorDataModel?> _latestSensorDataPerField = {};
  final Map<String, FlowMeterModel?> _latestFlowDataPerField = {};
  String? _lastActionError;

  Map<String, SensorDataModel?> get latestSensorDataPerField => _latestSensorDataPerField;
  Map<String, FlowMeterModel?> get latestFlowDataPerField => _latestFlowDataPerField;
  String? get lastActionError => _lastActionError;

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

  void _startAggTimer(String userId) {
    _aggTimer?.cancel();
    _aggTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _refreshDailySoilAverage();
      await _refreshWeeklyWaterUsage();
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
        notifyListeners();
      }).catchError((_) {});
      // Sensor readings
      _sensorDataService.streamLatestReading(fieldId).listen((sensorData) {
        _latestSensorDataPerField[fieldId] = sensorData;
        // Update live aggregates quickly from latest values
        _refreshDailySoilAverage();
        notifyListeners();
      });
      // Flow meter optional: ignore if collection doesn't exist
      _flowMeterService.getLatestReading(fieldId, userId: userId).then((flowData) {
        _latestFlowDataPerField[fieldId] = flowData;
        notifyListeners();
      }).catchError((_) {});
      _flowMeterService.streamLatestReading(fieldId, userId: userId).listen((flowData) {
        _latestFlowDataPerField[fieldId] = flowData;
        _refreshWeeklyWaterUsage(userId: userId);
        notifyListeners();
      }, onError: (_) {});
    }
    _startAggTimer(userId);
  }
}

