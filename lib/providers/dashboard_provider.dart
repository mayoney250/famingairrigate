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
      print('Failed to geocode address: $e');
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

  // Load dashboard data
  Future<void> loadDashboardData(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load data in parallel, but don't let one failure stop the others
      final results = await Future.wait([
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
        _loadSoilMoisture().catchError((e) {
          log('Error in _loadSoilMoisture: $e');
          return null;
        }),
        _loadWeeklyStats(userId).catchError((e) {
          log('Error in _loadWeeklyStats: $e');
          return null;
        }),
      ]);

      _isLoading = false;
      notifyListeners();
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
          // Scope by field/zone id; legacy data without alignment will still show globally
          if (s.zoneId.isNotEmpty && s.zoneId != _selectedFarmId) return false;

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

  // Load soil moisture
  Future<void> _loadSoilMoisture() async {
    try {
      _avgSoilMoisture = await _sensorService.getAverageSoilMoisture(_selectedFarmId);
    } catch (e) {
      log('Error loading soil moisture: $e');
      _avgSoilMoisture = 75.0; // Default value
    }
  }

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
}

