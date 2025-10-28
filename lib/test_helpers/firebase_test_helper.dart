import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/irrigation_zone_service.dart';
import '../services/irrigation_schedule_service.dart';
import '../services/sensor_data_service.dart';
import '../services/alert_service.dart';
import '../services/weather_service.dart';
import '../services/irrigation_log_service.dart';
import '../models/irrigation_zone_model.dart';
import '../models/irrigation_schedule_model.dart';
import '../models/sensor_data_model.dart';
import '../models/weather_data_model.dart';

class FirebaseTestHelper {
  static String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in! Please log in first.');
    }
    return user.uid;
  }
  
  /// Run all Firebase backend tests
  static Future<void> runAllTests() async {
    log('\n🧪 ========================================');
    log('   FAMINGA IRRIGATION BACKEND TESTS');
    log('========================================\n');
    
    try {
      // Check authentication
      if (FirebaseAuth.instance.currentUser == null) {
        log('❌ No user logged in!');
        log('Please log in and try again.\n');
        return;
      }
      
      log('👤 Testing as user: $userId\n');
      
      // Test 1: Zones
      log('📍 Test 1: Creating irrigation zone...');
      final zoneId = await _testCreateZone();
      log('✅ Zone created: $zoneId\n');
      
      // Test 2: Schedules
      log('📅 Test 2: Creating irrigation schedule...');
      final scheduleId = await _testCreateSchedule(zoneId);
      log('✅ Schedule created: $scheduleId\n');
      
      // Test 3: Sensor Data
      log('📊 Test 3: Adding sensor data...');
      final sensorId = await _testAddSensorData();
      log('✅ Sensor data added: $sensorId\n');
      
      // Test 4: Alerts
      log('🔔 Test 4: Creating alert...');
      final alertId = await _testCreateAlert();
      log('✅ Alert created: $alertId\n');
      
      // Test 5: Logs
      log('💧 Test 5: Logging irrigation...');
      await _testLogIrrigation(zoneId);
      log('✅ Irrigation logged\n');
      
      // Test 6: Weather
      log('🌤️  Test 6: Saving weather data...');
      final weatherId = await _testSaveWeather();
      log('✅ Weather saved: $weatherId\n');
      
      log('========================================');
      log('🎉 ALL TESTS PASSED SUCCESSFULLY!');
      log('========================================\n');
      log('✅ Check Firebase Console to see your data');
      log('✅ Open Collections:');
      log('   - irrigationZones');
      log('   - irrigationSchedules');
      log('   - sensorData');
      log('   - alerts');
      log('   - weatherData');
      log('   - irrigationLogs\n');
      
    } catch (e, stackTrace) {
      log('\n❌ ========================================');
      log('   TEST FAILED');
      log('========================================');
      log('Error: $e');
      log('Stack trace: $stackTrace\n');
      rethrow;
    }
  }
  
  static Future<String> _testCreateZone() async {
    final zoneService = IrrigationZoneService();
    final zone = IrrigationZoneModel(
      id: '',
      userId: userId,
      fieldId: 'test_field_1',
      name: 'Test Zone A',
      areaHectares: 2.5,
      cropType: 'Maize',
      isActive: true,
      waterUsageToday: 0,
      waterUsageThisWeek: 0,
      createdAt: DateTime.now(),
    );
    return await zoneService.createZone(zone);
  }
  
  static Future<String> _testCreateSchedule(String zoneId) async {
    final scheduleService = IrrigationScheduleService();
    final schedule = IrrigationScheduleModel(
      id: '',
      userId: userId,
      name: 'Test Morning Irrigation',
      zoneId: zoneId,
      zoneName: 'Test Zone A',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      durationMinutes: 30,
      repeatDays: const [1, 3, 5], // Mon, Wed, Fri
      isActive: true,
      createdAt: DateTime.now(),
    );
    return await scheduleService.createSchedule(schedule);
  }
  
  static Future<String> _testAddSensorData() async {
    final sensorService = SensorDataService();
    final reading = SensorDataModel(
      id: '',
      userId: userId,
      fieldId: 'test_field_1',
      sensorId: 'test_sensor_A',
      soilMoisture: 45.0, // 45%
      temperature: 24.0, // 24°C
      humidity: 65.0, // 65%
      battery: 87, // 87%
      timestamp: DateTime.now(),
    );
    return await sensorService.createReading(reading);
  }
  
  static Future<String> _testCreateAlert() async {
    final alertService = AlertService();
    return await alertService.createLowMoistureAlert(
      userId,
      'test_field_1',
      'Test Zone A',
      28.5, // Low moisture level
    );
  }
  
  static Future<void> _testLogIrrigation(String zoneId) async {
    final logService = IrrigationLogService();
    
    // Log start
    await logService.logIrrigationStart(
      userId,
      zoneId,
      'Test Zone A',
      triggeredBy: 'test',
    );
    
    // Log completion
    await logService.logIrrigationCompleted(
      userId,
      zoneId,
      'Test Zone A',
      30, // duration
      1234.5, // water used
      triggeredBy: 'test',
    );
  }
  
  static Future<String> _testSaveWeather() async {
    final weatherService = WeatherService();
    final weather = WeatherDataModel(
      id: '',
      userId: userId,
      location: 'Kigali, Rwanda',
      temperature: 24.0,
      humidity: 65.0,
      condition: 'Partly Cloudy',
      description: 'Partly cloudy with 65% humidity',
      timestamp: DateTime.now(),
    );
    return await weatherService.saveWeatherData(weather);
  }
}

