# 🔔 Local Notifications Setup (No Cloud Functions Required)

## ✅ What Has Been Implemented

Your notification system now works **completely client-side** without requiring Firebase Cloud Functions or billing!

### How It Works

All notifications are handled directly in the Flutter app using:
- **Firestore Listeners** for real-time monitoring (instant notifications)
- **Periodic Checks** every 30 minutes while app is running
- **Local Notifications** for displaying alerts

---

## 📱 Features Implemented

### 1. **Real-Time Irrigation Notifications**
When irrigation status changes (start, stop, complete, fail), you get instant notifications via Firestore listeners.

✅ **Triggers:**
- Irrigation starts (manual or scheduled) → "💧 Irrigation Started"
- Irrigation completes → "✅ Irrigation Completed" (with water usage)
- Irrigation stopped manually → "⏸️ Irrigation Stopped"
- Irrigation fails → "❌ Irrigation Failed"

### 2. **Soil Moisture Monitoring**
Real-time listener on sensor readings + periodic check every 30 minutes.

✅ **Triggers:**
- Soil moisture drops below **50%** → "💧 Irrigation Needed"
- 6-hour cooldown to prevent spam

### 3. **Water Level Monitoring**
Real-time listener on sensor readings + periodic check every 30 minutes.

✅ **Triggers:**
- Water level below 20% → "⚠️ Low Water Level"
- Water level below 10% → "🚨 Critical: Water Level Alert"
- 4-hour cooldown to prevent spam

### 4. **Schedule Reminders**
Checked every 30 minutes while app is running.

✅ **Triggers:**
- 30 minutes before scheduled irrigation → "⏰ Irrigation Reminder"

### 5. **Rain Forecast Alerts** 🌧️
Checked every 3 hours using OpenWeatherMap API.

✅ **Triggers:**
- Rain expected within 24 hours → "🌧️ Rain Forecast"
- Shows when rain is expected and probability
- 12-hour cooldown per field

**Setup Required:** See [WEATHER_API_SETUP.md](file:///c:/Users/famin/Documents/famingairrigate/WEATHER_API_SETUP.md) to get your free API key.

---

## 🚀 Setup Instructions

### Step 1: Get Weather API Key (Optional but Recommended)

For rain notifications to work, you need a free OpenWeatherMap API key:
1. Follow instructions in [WEATHER_API_SETUP.md](file:///c:/Users/famin/Documents/famingairrigate/WEATHER_API_SETUP.md)
2. Add your API key to [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart#L220)

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Run the App

```bash
flutter run
```

### Step 4: Grant Permissions

When the app starts:
1. **Allow notifications** when prompted (critical!)
2. The app will request notification permissions automatically
3. If you deny, notifications won't work

### Step 5: Test Notifications

1. **Login** to the app
2. The notification service will automatically initialize
3. Look for these in logs:
   - `✓ Notification permission granted`
   - `✓ Notification service initialized`
   - `✓ Irrigation listener setup`
   - `✓ Weather checks started`

---

## 🔍 How Each Notification Type Works

### Irrigation Status Changes (Real-Time)

```dart
// Firestore listener watches for changes
_firestore
  .collection('irrigation_cycles')
  .where('userId', isEqualTo: userId)
  .snapshots()
  .listen((snapshot) {
    // Instantly detects status changes
    // Shows notification immediately
  });
```

**No delay** - notifications appear as soon as the status changes in Firestore!

### Moisture & Water Level Checks (Background)

```dart
// Background task runs every 2 hours
Workmanager().registerPeriodicTask(
  'checkLevels',
  'checkLevelsTask',
  frequency: Duration(hours: 2),
);
```

**Checks every 2 hours** even when app is closed (Android only - iOS has limitations).

### Schedule Reminders (Background)

```dart
// Background task runs every 15 minutes
Workmanager().registerPeriodicTask(
  'checkSchedules',
  'checkSchedulesTask',
  frequency: Duration(minutes: 15),
);
```

**Checks every 15 minutes** to catch schedules 30 minutes before they start.

---

## ⚙️ Customization

### Change Moisture Threshold

Edit [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart#L277):

```dart
final threshold = sensor['lowThreshold'] ?? 50.0; // Change 50.0 to your value
```

Or set `lowThreshold` on individual sensors in Firestore.

### Change Check Frequency

Edit [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart#L62):

```dart
// Moisture & water checks
await Workmanager().registerPeriodicTask(
  'checkLevels',
  'checkLevelsTask',
  frequency: const Duration(hours: 1), // Change from 2 hours to 1 hour
);

// Schedule checks
await Workmanager().registerPeriodicTask(
  'checkSchedules',
  'checkSchedulesTask',
  frequency: const Duration(minutes: 30), // Change from 15 to 30 minutes
);
```

**Note:** Minimum frequency on Android is 15 minutes.

### Change Cooldown Periods

Edit [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart):

```dart
// For moisture alerts (line ~311)
if (hoursSince < 6) { // Change from 6 to your desired hours

// For water alerts (line ~392)
if (hoursSince < 4) { // Change from 4 to your desired hours
```

---

## 📊 Permissions Required

### Android
The app requests these permissions automatically:
- ✅ **Notifications** - to display alerts
- ✅ **Internet** - to access Firestore
- ✅ **Wake Lock** - to run background tasks
- ✅ **Boot Completed** - to restart tasks after reboot

### iOS
- ✅ **Notifications** - requested on first launch
- ⚠️ **Background tasks** - iOS limits background execution significantly

**Note:** Background tasks work best on Android. On iOS, the app needs to be open or recently active for most notifications.

---

## 🧪 Testing

### Test 1: Irrigation Start Notification

1. Log into the app
2. Start an irrigation cycle or update status to `running` in Firestore
3. You should see: "💧 Irrigation Started"

### Test 2: Irrigation Complete Notification

1. Update an active irrigation cycle status to `completed` in Firestore
2. You should see: "✅ Irrigation Completed"

### Test 3: Low Moisture Alert

1. Add a sensor reading with moisture < 50%:
```dart
await FirebaseFirestore.instance.collection('sensor_readings').add({
  'sensorId': 'your_sensor_id',
  'value': 45.0,
  'timestamp': Timestamp.now(),
});
```
2. Wait up to 2 hours (or trigger background task manually)
3. You should see: "💧 Irrigation Needed"

### Test 4: Force Background Task (Android Debug)

```bash
adb shell cmd jobscheduler run -f com.faminga.irrigation 1
```

This manually triggers the background task for testing.

---

## 🔍 Troubleshooting

### Notifications Not Showing?

1. **Check Permissions**
   - Android: Settings → Apps → Faminga Irrigation → Notifications → Ensure enabled
   - iOS: Settings → Faminga Irrigation → Notifications → Ensure enabled

2. **Check Battery Optimization (Android)**
   - Settings → Battery → Battery Optimization
   - Find "Faminga Irrigation" → Select "Don't optimize"
   - Some manufacturers (Xiaomi, Huawei, Samsung) have aggressive battery savers

3. **Check App Logs**
   ```bash
   flutter logs
   ```
   Look for:
   - `✓ Notification service initialized`
   - `✓ Background tasks registered`
   - `✓ Irrigation listener setup`
   - `✓ Notification sent: [title]`

4. **Verify Firestore Data**
   - Ensure sensors exist in Firestore
   - Ensure sensor readings are being added
   - Ensure irrigation cycles are being created/updated

### Background Tasks Not Running?

1. **Android Only**: Background tasks work reliably on Android but have severe limitations on iOS.

2. **Check WorkManager**: On Android, open:
   - Settings → Developer Options → JobScheduler Jobs
   - Look for `com.faminga.irrigation` jobs

3. **Reinstall App**: Sometimes WorkManager needs a fresh install to register properly.

---

## 🆚 Comparison: Cloud Functions vs. Local

| Feature | Cloud Functions | Local (Current) |
|---------|----------------|-----------------|
| **Cost** | Requires billing | ✅ **FREE** |
| **Reliability** | ⚡ Very reliable | ✅ Reliable on Android, limited on iOS |
| **Battery Impact** | None | Minimal |
| **Real-time Triggers** | ✅ Instant | ✅ Instant (Firestore listeners) |
| **Scheduled Checks** | ✅ Precise timing | Every 15 mins minimum (Android) |
| **iOS Support** | ✅ Full support | ⚠️ Limited background execution |
| **Offline** | ❌ Needs server | ✅ Works when app opens |

---

## 📂 Files Modified/Created

1. ✅ [pubspec.yaml](file:///c:/Users/famin/Documents/famingairrigate/pubspec.yaml) - Added `workmanager`
2. ✅ [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart) - NEW: Complete notification logic
3. ✅ [lib/providers/auth_provider.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/providers/auth_provider.dart) - Uses NotificationService instead of FCMService
4. ✅ [lib/main.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/main.dart) - Removed FCM background handler
5. ✅ [android/app/src/main/AndroidManifest.xml](file:///c:/Users/famin/Documents/famingairrigate/android/app/src/main/AndroidManifest.xml) - Added permissions

---

## ✅ What to Do Now

1. Run `flutter pub get` to install dependencies
2. Run the app: `flutter run`
3. Login and grant notification permissions
4. Test by creating irrigation cycles or adding sensor readings
5. Check app logs to verify notifications are working

---

## 💡 Important Notes

### For Production

- **Android users** will get reliable notifications
- **iOS users** will get notifications when app is active or recently used
- Consider Cloud Functions if you need 100% reliable iOS background notifications (requires billing)

### Battery Optimization

Inform users to:
1. Disable battery optimization for the app
2. Allow background activity
3. Keep app running in background (don't force-close)

### Firestore Costs

All notification logic runs client-side, but:
- Firestore listeners count as reads
- Background tasks query Firestore every 2 hours
- Monitor your Firestore usage in Firebase Console

**Estimated Firestore usage:**
- ~12 reads per sensor per day (background checks)
- Real-time listeners (minimal cost)
- Should stay well within free tier for typical usage

---

## 🎉 Summary

✅ **No Cloud Functions needed** - everything runs locally  
✅ **No Firebase billing required** - completely free  
✅ **Real-time notifications** - instant irrigation status updates  
✅ **Background monitoring** - checks moisture and water levels every 2 hours  
✅ **Works offline** - catches up when reconnected  
✅ **All 4 notification types implemented**:
  - Irrigation start/end
  - Low moisture (< 50%)
  - Low water levels
  - Schedule reminders

Your notifications are ready to go! 🚀
