# 🧪 Complete Irrigation System Testing Guide

## ✅ What Has Been Implemented

### Backend Infrastructure (100% Complete)

#### 📦 Data Models Created
1. **IrrigationScheduleModel** - Schedule irrigation tasks
2. **IrrigationZoneModel** - Define irrigation zones
3. **SensorDataModel** - Store sensor readings
4. **AlertModel** - System notifications and alerts
5. **WeatherDataModel** - Weather information
6. **IrrigationLogModel** - Activity logging

#### 🔧 Firebase Services Created
1. **IrrigationScheduleService** - CRUD operations for schedules
2. **IrrigationZoneService** - Manage irrigation zones
3. **SensorDataService** - Handle sensor data
4. **AlertService** - Create and manage alerts
5. **WeatherService** - Weather data management
6. **IrrigationLogService** - Activity logging

---

## 🗄️ Firestore Database Collections

### Collection Structure

```
firestore/
├── irrigationSchedules/     # User irrigation schedules
│   └── {scheduleId}
│       ├── id: string
│       ├── userId: string
│       ├── name: string (e.g., "Morning Irrigation")
│       ├── zoneId: string
│       ├── zoneName: string
│       ├── startTime: timestamp
│       ├── durationMinutes: number
│       ├── repeatDays: array[int] (1=Mon, 7=Sun)
│       ├── isActive: boolean
│       ├── createdAt: timestamp
│       ├── lastRun: timestamp?
│       └── nextRun: timestamp?
│
├── irrigationZones/        # Irrigation zones/areas
│   └── {zoneId}
│       ├── id: string
│       ├── userId: string
│       ├── fieldId: string
│       ├── name: string (e.g., "Zone A")
│       ├── areaHectares: number
│       ├── cropType: string?
│       ├── isActive: boolean
│       ├── waterUsageToday: number (liters)
│       ├── waterUsageThisWeek: number (liters)
│       ├── createdAt: timestamp
│       └── lastIrrigation: timestamp?
│
├── sensorData/            # Real-time sensor readings
│   └── {readingId}
│       ├── id: string
│       ├── userId: string
│       ├── fieldId: string
│       ├── sensorId: string?
│       ├── soilMoisture: number (%)
│       ├── temperature: number (°C)
│       ├── humidity: number (%)
│       ├── battery: number? (%)
│       └── timestamp: timestamp
│
├── alerts/                # System alerts
│   └── {alertId}
│       ├── id: string
│       ├── userId: string
│       ├── fieldId: string?
│       ├── zoneId: string?
│       ├── type: string (lowMoisture, highTemperature, etc.)
│       ├── severity: string (info, warning, critical)
│       ├── title: string
│       ├── message: string
│       ├── isRead: boolean
│       └── timestamp: timestamp
│
├── weatherData/           # Weather information
│   └── {weatherId}
│       ├── id: string
│       ├── userId: string
│       ├── location: string
│       ├── temperature: number (°C)
│       ├── humidity: number (%)
│       ├── condition: string (Sunny, Cloudy, etc.)
│       ├── description: string
│       ├── timestamp: timestamp
│       └── lastUpdated: timestamp?
│
└── irrigationLogs/        # Activity logs
    └── {logId}
        ├── id: string
        ├── userId: string
        ├── zoneId: string
        ├── zoneName: string
        ├── action: string (started, stopped, completed, failed)
        ├── durationMinutes: number?
        ├── waterUsed: number? (liters)
        ├── scheduleId: string?
        ├── triggeredBy: string (manual, schedule, auto)
        ├── notes: string?
        └── timestamp: timestamp
```

---

## 🔐 Firebase Security Rules

### Deploy These Rules to Firebase

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Irrigation Schedules
    match /irrigationSchedules/{scheduleId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
    
    // Irrigation Zones
    match /irrigationZones/{zoneId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
    
    // Sensor Data
    match /sensorData/{readingId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
    
    // Alerts
    match /alerts/{alertId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
    
    // Weather Data
    match /weatherData/{weatherId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
    
    // Irrigation Logs
    match /irrigationLogs/{logId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 🧪 Manual Testing Guide

### Prerequisites
1. Firebase project set up
2. Firestore database created
3. Security rules deployed
4. App running: `flutter run -d chrome`
5. User logged in

---

### Test 1: Create Irrigation Zone

```dart
// Use Firebase Console or write a test function
import 'package:famingairrigate/services/irrigation_zone_service.dart';
import 'package:famingairrigate/models/irrigation_zone_model.dart';

Future<void> testCreateZone() async {
  final zoneService = IrrigationZoneService();
  
  final zone = IrrigationZoneModel(
    id: '',
    userId: 'YOUR_USER_ID', // Get from Firebase Auth
    fieldId: 'field_1',
    name: 'Zone A',
    areaHectares: 2.5,
    cropType: 'Maize',
    isActive: true,
    waterUsageToday: 0,
    waterUsageThisWeek: 0,
    createdAt: DateTime.now(),
  );
  
  final zoneId = await zoneService.createZone(zone);
  print('Zone created with ID: $zoneId');
}
```

**Verify in Firebase Console:**
1. Go to Firestore Database
2. Navigate to `irrigationZones` collection
3. You should see your new zone document

---

### Test 2: Create Irrigation Schedule

```dart
import 'package:famingairrigate/services/irrigation_schedule_service.dart';
import 'package:famingairrigate/models/irrigation_schedule_model.dart';

Future<void> testCreateSchedule() async {
  final scheduleService = IrrigationScheduleService();
  
  final schedule = IrrigationScheduleModel(
    id: '',
    userId: 'YOUR_USER_ID',
    name: 'Morning Irrigation',
    zoneId: 'ZONE_ID_FROM_TEST_1',
    zoneName: 'Zone A',
    startTime: DateTime.now().add(Duration(hours: 1)),
    durationMinutes: 30,
    repeatDays: [1, 3, 5], // Monday, Wednesday, Friday
    isActive: true,
    createdAt: DateTime.now(),
  );
  
  final scheduleId = await scheduleService.createSchedule(schedule);
  print('Schedule created with ID: $scheduleId');
}
```

**Verify in Firebase Console:**
1. Go to `irrigationSchedules` collection
2. Confirm schedule document exists
3. Check all fields are correctly saved

---

### Test 3: Add Sensor Data

```dart
import 'package:famingairrigate/services/sensor_data_service.dart';
import 'package:famingairrigate/models/sensor_data_model.dart';

Future<void> testAddSensorData() async {
  final sensorService = SensorDataService();
  
  final reading = SensorDataModel(
    id: '',
    userId: 'YOUR_USER_ID',
    fieldId: 'field_1',
    sensorId: 'sensor_A',
    soilMoisture: 45.0, // 45%
    temperature: 24.0, // 24°C
    humidity: 65.0, // 65%
    battery: 87, // 87%
    timestamp: DateTime.now(),
  );
  
  final readingId = await sensorService.createReading(reading);
  print('Sensor reading created with ID: $readingId');
}
```

**Verify in Firebase Console:**
1. Go to `sensorData` collection
2. Check the reading is saved
3. Verify all sensor values

---

### Test 4: Create Alert

```dart
import 'package:famingairrigate/services/alert_service.dart';

Future<void> testCreateAlert() async {
  final alertService = AlertService();
  
  final alertId = await alertService.createLowMoistureAlert(
    'YOUR_USER_ID',
    'field_1',
    'Zone A',
    28.5, // Moisture level
  );
  
  print('Alert created with ID: $alertId');
}
```

**Verify in Firebase Console:**
1. Go to `alerts` collection
2. Check alert document
3. Verify type, severity, and message

---

### Test 5: Log Irrigation Activity

```dart
import 'package:famingairrigate/services/irrigation_log_service.dart';

Future<void> testLogIrrigation() async {
  final logService = IrrigationLogService();
  
  // Start irrigation
  final logId = await logService.logIrrigationStart(
    'YOUR_USER_ID',
    'ZONE_ID',
    'Zone A',
    triggeredBy: 'manual',
  );
  
  print('Irrigation started, log ID: $logId');
  
  // Simulate irrigation running for 30 minutes
  await Future.delayed(Duration(seconds: 5));
  
  // Complete irrigation
  final completeLogId = await logService.logIrrigationCompleted(
    'YOUR_USER_ID',
    'ZONE_ID',
    'Zone A',
    30, // duration
    1234.5, // water used (liters)
    triggeredBy: 'manual',
  );
  
  print('Irrigation completed, log ID: $completeLogId');
}
```

**Verify in Firebase Console:**
1. Go to `irrigationLogs` collection
2. Check for 2 documents (started and completed)
3. Verify timestamps and data

---

### Test 6: Save Weather Data

```dart
import 'package:famingairrigate/services/weather_service.dart';
import 'package:famingairrigate/models/weather_data_model.dart';

Future<void> testSaveWeather() async {
  final weatherService = WeatherService();
  
  final weather = WeatherDataModel(
    id: '',
    userId: 'YOUR_USER_ID',
    location: 'Kigali',
    temperature: 24.0,
    humidity: 65.0,
    condition: 'Partly Cloudy',
    description: 'Partly cloudy with humidity 65%',
    timestamp: DateTime.now(),
  );
  
  final weatherId = await weatherService.saveWeatherData(weather);
  print('Weather data saved with ID: $weatherId');
}
```

---

## 🔧 Integration Testing

### Create Test Helper Function

Create file: `lib/test_helpers/firebase_test_helper.dart`

```dart
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
  static String get userId => FirebaseAuth.instance.currentUser!.uid;
  
  // Test all services
  static Future<void> runAllTests() async {
    print('🧪 Starting Firebase backend tests...\n');
    
    try {
      // Test 1: Create Zone
      print('📍 Test 1: Creating irrigation zone...');
      final zoneId = await testCreateZone();
      print('✅ Zone created: $zoneId\n');
      
      // Test 2: Create Schedule
      print('📅 Test 2: Creating irrigation schedule...');
      final scheduleId = await testCreateSchedule(zoneId);
      print('✅ Schedule created: $scheduleId\n');
      
      // Test 3: Add Sensor Data
      print('📊 Test 3: Adding sensor data...');
      final sensorId = await testAddSensorData();
      print('✅ Sensor data added: $sensorId\n');
      
      // Test 4: Create Alert
      print('🔔 Test 4: Creating alert...');
      final alertId = await testCreateAlert();
      print('✅ Alert created: $alertId\n');
      
      // Test 5: Log Irrigation
      print('💧 Test 5: Logging irrigation...');
      await testLogIrrigation(zoneId);
      print('✅ Irrigation logged\n');
      
      // Test 6: Save Weather
      print('🌤️  Test 6: Saving weather data...');
      final weatherId = await testSaveWeather();
      print('✅ Weather saved: $weatherId\n');
      
      print('🎉 All tests passed!');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }
  
  static Future<String> testCreateZone() async {
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
  
  static Future<String> testCreateSchedule(String zoneId) async {
    final scheduleService = IrrigationScheduleService();
    final schedule = IrrigationScheduleModel(
      id: '',
      userId: userId,
      name: 'Test Morning Irrigation',
      zoneId: zoneId,
      zoneName: 'Test Zone A',
      startTime: DateTime.now().add(Duration(hours: 1)),
      durationMinutes: 30,
      repeatDays: [1, 3, 5],
      isActive: true,
      createdAt: DateTime.now(),
    );
    return await scheduleService.createSchedule(schedule);
  }
  
  static Future<String> testAddSensorData() async {
    final sensorService = SensorDataService();
    final reading = SensorDataModel(
      id: '',
      userId: userId,
      fieldId: 'test_field_1',
      sensorId: 'test_sensor_A',
      soilMoisture: 45.0,
      temperature: 24.0,
      humidity: 65.0,
      battery: 87,
      timestamp: DateTime.now(),
    );
    return await sensorService.createReading(reading);
  }
  
  static Future<String> testCreateAlert() async {
    final alertService = AlertService();
    return await alertService.createLowMoistureAlert(
      userId,
      'test_field_1',
      'Test Zone A',
      28.5,
    );
  }
  
  static Future<void> testLogIrrigation(String zoneId) async {
    final logService = IrrigationLogService();
    await logService.logIrrigationStart(
      userId,
      zoneId,
      'Test Zone A',
      triggeredBy: 'test',
    );
    await logService.logIrrigationCompleted(
      userId,
      zoneId,
      'Test Zone A',
      30,
      1234.5,
      triggeredBy: 'test',
    );
  }
  
  static Future<String> testSaveWeather() async {
    final weatherService = WeatherService();
    final weather = WeatherDataModel(
      id: '',
      userId: userId,
      location: 'Kigali',
      temperature: 24.0,
      humidity: 65.0,
      condition: 'Partly Cloudy',
      description: 'Test weather data',
      timestamp: DateTime.now(),
    );
    return await weatherService.saveWeatherData(weather);
  }
}
```

### Run Tests from Your App

Add a test button to your dashboard or settings:

```dart
// In your screen
ElevatedButton(
  onPressed: () async {
    await FirebaseTestHelper.runAllTests();
  },
  child: Text('Run Backend Tests'),
)
```

---

## 📱 Testing from Firebase Console

### Manual Data Entry

1. **Go to Firebase Console** → Firestore Database

2. **Create Test Zone:**
   - Click "Start collection"
   - Collection ID: `irrigationZones`
   - Document ID: Auto-generate
   - Add fields:
     ```
     userId: YOUR_USER_ID
     fieldId: test_field_1
     name: Zone A
     areaHectares: 2.5
     cropType: Maize
     isActive: true
     waterUsageToday: 0
     waterUsageThisWeek: 0
     createdAt: [timestamp now]
     ```

3. **Create Test Schedule:**
   - Collection: `irrigationSchedules`
   - Add fields as per model

4. **Add Sensor Data:**
   - Collection: `sensorData`
   - Add current readings

---

## 🎯 Verification Checklist

### For Each Collection

- [ ] **irrigationZones**
  - [ ] Can create zone
  - [ ] Can read zones for user
  - [ ] Can update zone
  - [ ] Can toggle zone active status
  - [ ] Can delete zone
  - [ ] Water usage updates correctly

- [ ] **irrigationSchedules**
  - [ ] Can create schedule
  - [ ] Can read schedules for user
  - [ ] Can update schedule
  - [ ] Can toggle schedule active status
  - [ ] Can delete schedule
  - [ ] Next run time calculates correctly

- [ ] **sensorData**
  - [ ] Can create reading
  - [ ] Can get latest reading
  - [ ] Can get historical data
  - [ ] Charts show correct data

- [ ] **alerts**
  - [ ] Can create alert
  - [ ] Can mark as read
  - [ ] Can get unread count
  - [ ] Different alert types work

- [ ] **weatherData**
  - [ ] Can save weather
  - [ ] Can get today's weather
  - [ ] Updates existing data

- [ ] **irrigationLogs**
  - [ ] Can log start
  - [ ] Can log completion
  - [ ] Can get today's logs
  - [ ] Water usage calculates correctly

---

## 🚀 Quick Start Testing

### Option 1: Using Firebase Console (Easiest)

1. **Sign in to Firebase Console**
2. **Go to Firestore Database**
3. **Manually add test data** using the structures above
4. **Open your app** and verify data appears

### Option 2: Using Test Helper (Recommended)

1. **Copy the `FirebaseTestHelper` code** above
2. **Create the file** `lib/test_helpers/firebase_test_helper.dart`
3. **Add test button** to your app
4. **Run tests** and check Firebase Console

### Option 3: Using Dart Console

1. **Create** `test/firebase_test.dart`
2. **Run:** `flutter test test/firebase_test.dart`

---

## 🐛 Troubleshooting

### Issue: Permission Denied
**Solution:** Deploy security rules to Firebase

### Issue: Collection Not Found
**Solution:** Create first document manually in Firebase Console

### Issue: Data Not Showing
**Solution:** Check userId matches logged-in user

### Issue: Timestamp Errors
**Solution:** Import `package:cloud_firestore/cloud_firestore.dart`

---

## 📊 Expected Results

After running all tests successfully:

```
✅ Firebase Collections Created:
   ├── irrigationZones (1+ documents)
   ├── irrigationSchedules (1+ documents)
   ├── sensorData (1+ documents)
   ├── alerts (1+ documents)
   ├── weatherData (1+ documents)
   └── irrigationLogs (2+ documents)

✅ All CRUD Operations Work
✅ Security Rules Applied
✅ Real-time Updates Functional
✅ Data Persists Correctly
```

---

## 🎉 Success Criteria

Your backend is fully functional when:

1. ✅ All 6 collections exist in Firestore
2. ✅ Test data can be created in each collection
3. ✅ Data can be read, updated, and deleted
4. ✅ Security rules allow user access to their data only
5. ✅ Real-time streams update UI automatically
6. ✅ All services work without errors
7. ✅ Firebase Console shows all test data

---

**🚀 Your irrigation system backend is now fully implemented and testable!**

