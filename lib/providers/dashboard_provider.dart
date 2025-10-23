import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/irrigation_schedule_model.dart';
import '../models/weather_model.dart';
import '../services/irrigation_service.dart';
import '../services/sensor_service.dart';
import '../services/weather_service.dart';

class DashboardProvider with ChangeNotifier {
  final IrrigationService _irrigationService = IrrigationService();
  final SensorService _sensorService = SensorService();
  final WeatherService _weatherService = WeatherService();

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  
  // Dashboard data
  IrrigationSchedule? _nextSchedule;
  WeatherData? _weatherData;
  double _soilMoisture = 75.0;
  double _weeklyWaterUsage = 0.0;
  double _weeklySavings = 0.0;
  String _selectedFarmId = 'farm1'; // Default farm

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  IrrigationSchedule? get nextSchedule => _nextSchedule;
  WeatherData? get weatherData => _weatherData;
  double get soilMoisture => _soilMoisture;
  double get weeklyWaterUsage => _weeklyWaterUsage;
  double get weeklySavings => _weeklySavings;
  String get selectedFarmId => _selectedFarmId;

  // Get soil moisture status message
  String get soilMoistureStatus {
    return _sensorService.getSoilMoistureStatus(_soilMoisture);
  }

  // Get system status
  String get systemStatus {
    if (_soilMoisture < 40) {
      return 'Attention Required';
    } else if (_soilMoisture >= 60 && _soilMoisture <= 80) {
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
      return 'Everything is fully loaded. ${_weatherService.getIrrigationRecommendation(_weatherData!)}';
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

      // Load data in parallel
      await Future.wait([
        _loadNextSchedule(userId),
        _loadWeatherData(),
        _loadSoilMoisture(),
        _loadWeeklyStats(userId),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      _isLoading = false;
      log('Error loading dashboard data: $e');
      notifyListeners();
    }
  }

  // Load next scheduled irrigation
  Future<void> _loadNextSchedule(String userId) async {
    try {
      _nextSchedule = await _irrigationService.getNextSchedule(userId);
    } catch (e) {
      log('Error loading next schedule: $e');
    }
  }

  // Load weather data
  Future<void> _loadWeatherData() async {
    try {
      _weatherData = await _weatherService.getDefaultWeather();
    } catch (e) {
      log('Error loading weather data: $e');
      // Use mock data if API fails
      _weatherData = WeatherData(
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
  }

  // Load soil moisture
  Future<void> _loadSoilMoisture() async {
    try {
      _soilMoisture = await _sensorService.getAverageSoilMoisture(_selectedFarmId);
    } catch (e) {
      log('Error loading soil moisture: $e');
      _soilMoisture = 75.0; // Default value
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
      final success = await _irrigationService.startIrrigationManually(
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

  // Refresh dashboard
  Future<void> refresh(String userId) async {
    await loadDashboardData(userId);
  }

  // Change selected farm
  void selectFarm(String farmId) {
    if (_selectedFarmId != farmId) {
      _selectedFarmId = farmId;
      notifyListeners();
    }
  }

  // Generate mock sensor reading for testing
  Future<void> generateMockSensorData() async {
    try {
      await _sensorService.generateMockReading(
        _selectedFarmId,
        'field1',
      );
      await _loadSoilMoisture();
      notifyListeners();
    } catch (e) {
      log('Error generating mock sensor data: $e');
    }
  }
}

