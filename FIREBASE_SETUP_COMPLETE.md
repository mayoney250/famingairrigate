# 🔥 Complete Firebase Setup Guide

## Current Issues & Solutions

### Issue 1: Firebase Index Errors ❌
**Error:** `The query requires an index`

**Solution:** Deploy Firebase indexes

### Issue 2: No Data in Firebase ❌
**Error:** Collections are empty, showing mock/hardcoded data

**Solution:** Run the test helper to populate Firebase

### Issue 3: Irrigation Control Issues ❌
**Error:** No stop button, blank irrigation page

**Solution:** Fixed in this update

---

## 🚀 Quick Fix (5 Minutes)

### Step 1: Deploy Firebase Indexes (2 minutes)

**Option A: Automatic (Using Firebase CLI - Recommended)**

1. **Install Firebase CLI** (if not installed):
```bash
npm install -g firebase-tools
```

2. **Login to Firebase:**
```bash
firebase login
```

3. **Initialize Firebase in your project:**
```bash
cd famingairrigate
firebase init firestore
```
- Select your project: `ngairrigate`
- Use default files (firestore.rules, firestore.indexes.json)
- **DON'T overwrite** the indexes file we just created

4. **Deploy the indexes:**
```bash
firebase deploy --only firestore:indexes
```

**Option B: Manual (Using Firebase Console)**

Click each link from the error messages:

1. **For irrigationSchedules index:**
   - Click the link from the error message
   - Or go to: Firebase Console → Firestore → Indexes → Create Index
   - Add fields: `userId` (Ascending), `isActive` (Ascending), `nextRun` (Ascending)
   - Click "Create Index"

2. **For weatherData index:**
   - Click the link from the error message
   - Add fields: `userId` (Ascending), `timestamp` (Ascending)
   - Click "Create Index"

3. **Wait 2-5 minutes** for indexes to build

---

### Step 2: Populate Firebase with Test Data (2 minutes)

**Add this button to your Dashboard temporarily:**

```dart
// Add to lib/screens/dashboard/dashboard_screen.dart
// Inside the Scaffold, add a floating action button:

floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      await FirebaseTestHelper.runAllTests();
      Get.back(); // Close loading
      Get.snackbar(
        'Success!',
        'Test data created. Check Firebase Console',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  },
  icon: const Icon(Icons.science),
  label: const Text('Run Tests'),
  backgroundColor: FamingaBrandColors.primaryOrange,
)
```

**Then:**
1. Run the app
2. Click "Run Tests" button
3. Wait for success message
4. Check Firebase Console - you'll see 6 collections with data!

---

### Step 3: Verify Everything Works (1 minute)

1. **Refresh the app** (hot reload or restart)
2. **Check Firebase Console:**
   - Go to Firestore Database
   - You should see these collections:
     - ✅ `irrigationZones`
     - ✅ `irrigationSchedules`
     - ✅ `sensorData`
     - ✅ `alerts`
     - ✅ `weatherData`
     - ✅ `irrigationLogs`

3. **Check the app:**
   - Dashboard should show real data
   - Irrigation control should work
   - No more index errors!

---

## 📊 What the Test Helper Creates

When you click "Run Tests", it creates:

### 1. Irrigation Zone
```
Zone A (Test Zone A)
- Area: 2.5 hectares
- Crop: Maize
- Status: Active
```

### 2. Irrigation Schedule
```
Test Morning Irrigation
- Zone: Test Zone A
- Duration: 30 minutes
- Repeats: Mon, Wed, Fri
- Status: Active
```

### 3. Sensor Data
```
Soil Moisture: 45%
Temperature: 24°C
Humidity: 65%
Battery: 87%
```

### 4. Alert
```
Low Soil Moisture Alert
Zone A moisture level: 28.5%
```

### 5. Weather Data
```
Location: Kigali, Rwanda
Temperature: 24°C
Humidity: 65%
Condition: Partly Cloudy
```

### 6. Irrigation Logs
```
2 logs:
- Irrigation Started (Test Zone A)
- Irrigation Completed (30 min, 1234.5L)
```

---

## 🎯 After Setup - Real Usage

Once you have test data, you can:

### Create Your Own Zones

```dart
final zoneService = IrrigationZoneService();

final myZone = IrrigationZoneModel(
  id: '',
  userId: FirebaseAuth.instance.currentUser!.uid,
  fieldId: 'my_field_1',
  name: 'North Field',
  areaHectares: 5.0,
  cropType: 'Potatoes',
  isActive: true,
  waterUsageToday: 0,
  waterUsageThisWeek: 0,
  createdAt: DateTime.now(),
);

await zoneService.createZone(myZone);
```

### Create Your Own Schedules

```dart
final scheduleService = IrrigationScheduleService();

final mySchedule = IrrigationScheduleModel(
  id: '',
  userId: FirebaseAuth.instance.currentUser!.uid,
  name: 'Evening Irrigation',
  zoneId: 'zone_id_here',
  zoneName: 'North Field',
  startTime: DateTime(2025, 10, 28, 18, 0), // 6 PM today
  durationMinutes: 45,
  repeatDays: [1, 2, 3, 4, 5], // Weekdays
  isActive: true,
  createdAt: DateTime.now(),
);

await scheduleService.createSchedule(mySchedule);
```

### Add Real Sensor Data

```dart
final sensorService = SensorDataService();

final reading = SensorDataModel(
  id: '',
  userId: FirebaseAuth.instance.currentUser!.uid,
  fieldId: 'my_field_1',
  sensorId: 'sensor_001',
  soilMoisture: 52.0,
  temperature: 26.5,
  humidity: 68.0,
  battery: 92,
  timestamp: DateTime.now(),
);

await sensorService.createReading(reading);
```

---

## 🐛 Troubleshooting

### Index Still Building
**Error:** Still getting index errors after deployment

**Solution:** Wait 5 minutes, then refresh. Indexes take time to build.

### Test Helper Fails
**Error:** Tests fail with permission denied

**Solution:** 
1. Check Firebase security rules are deployed
2. Make sure you're logged in
3. Verify userId matches your auth user

### No Data Showing
**Error:** Collections exist but app shows no data

**Solution:**
1. Verify userId in documents matches your auth user
2. Check console for errors
3. Try hot restart (not just hot reload)

### Irrigation Page Blank
**Error:** Irrigation control screen is empty

**Solution:**
1. First run the test helper to create zones
2. The screen needs at least one zone to display
3. Check console for errors

---

## 📝 Clean Up Test Data

After testing, you can delete test data:

**In Firebase Console:**
1. Go to Firestore Database
2. Open each collection
3. Delete documents with "Test" in the name

**Or keep it!** Test data is useful for development.

---

## ✅ Success Checklist

After following this guide:

- [ ] Firebase indexes deployed (no more index errors)
- [ ] Test data created (6 collections with documents)
- [ ] Dashboard shows real data
- [ ] Irrigation control shows zones
- [ ] Schedules page shows schedules
- [ ] No errors in console
- [ ] Can create new zones/schedules
- [ ] Data persists after refresh

---

## 🎉 You're All Set!

Once you complete these steps:
- ✅ Firebase is fully configured
- ✅ All queries work without errors
- ✅ You have sample data to work with
- ✅ You can create real data
- ✅ App is production-ready!

**Next:** Build your UI screens using the real Firebase data! 🚀

