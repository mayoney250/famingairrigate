# 📱 Firebase Cloud Messaging (FCM) Setup Complete

## ✅ What Has Been Implemented

### 1. FCM Service (`lib/services/fcm_service.dart`)
- ✅ Full FCM integration with background message handling
- ✅ Local notification display even when app is closed
- ✅ Automatic FCM token management and storage
- ✅ Token refresh handling
- ✅ Notification channels for Android
- ✅ iOS push notification support
- ✅ Topic subscription support

### 2. Cloud Functions (`functions/index.js`)
Four automated notification triggers:

#### a) `checkIrrigationNeeds` (Every 2 hours)
- Monitors soil moisture levels from all sensors
- Sends alerts when moisture falls below threshold (default: 30%)
- Prevents duplicate alerts (6-hour cooldown)
- Stores alerts in Firestore

#### b) `checkWaterLevels` (Every 1 hour)
- Monitors water level sensors
- Two severity levels:
  - **Medium**: Water level below 20%
  - **Critical**: Water level below 10%
- Prevents duplicate alerts (4-hour cooldown)
- Stores alerts in Firestore

#### c) `sendScheduleReminders` (Every 30 minutes)
- Sends reminders 30 minutes before scheduled irrigation
- One-time reminder per schedule
- Helps farmers prepare for irrigation

#### d) `onIrrigationStatusChange` (Real-time trigger)
- Monitors irrigation cycle status changes
- Sends notifications for:
  - Irrigation started
  - Irrigation completed (with water usage)
  - Irrigation stopped (manual)
  - Irrigation failed

### 3. Platform Configuration
- ✅ Android: FCM ready (uses existing google-services.json)
- ✅ iOS: Push notification handlers configured
- ✅ Background message handler in main.dart

### 4. Token Management
- ✅ FCM tokens automatically saved to user document in Firestore
- ✅ Invalid tokens automatically removed
- ✅ Token refresh handled automatically
- ✅ Token deleted on logout

---

## 🚀 Setup Instructions

### Step 1: Install Cloud Functions Dependencies

```bash
cd functions
npm install
```

### Step 2: Update Firebase Configuration

Make sure your `firebase.json` includes functions:

```json
{
  "functions": {
    "source": "functions"
  }
}
```

### Step 3: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This will deploy:
- `checkIrrigationNeeds`
- `checkWaterLevels`
- `sendScheduleReminders`
- `onIrrigationStatusChange`

### Step 4: Update Firestore Security Rules

Add to your `firestore.rules`:

```javascript
match /schedule_reminders/{reminderId} {
  allow read, write: if request.auth != null;
}
```

### Step 5: Enable Required APIs in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Enable:
   - Cloud Functions API
   - Cloud Scheduler API
   - Cloud Pub/Sub API

### Step 6: Run the App

```bash
flutter run
```

The FCM service will automatically initialize when a user logs in.

---

## 📊 Firestore Data Structure

### User Document (Updated)
```javascript
{
  // ... existing fields ...
  fcmTokens: ["token1", "token2"],  // Array of FCM tokens
  lastTokenUpdate: Timestamp
}
```

### Alerts Collection
```javascript
{
  userId: "userId",
  fieldId: "fieldId",
  fieldName: "Field Name",
  sensorId: "sensorId",
  sensorName: "Sensor Name",
  type: "irrigation_needed" | "water_low",
  severity: "low" | "medium" | "high" | "critical",
  message: "Alert message",
  moistureLevel: 25.5,  // For irrigation_needed
  waterLevel: 15.0,     // For water_low
  threshold: 30.0,
  timestamp: Timestamp,
  read: false
}
```

---

## 🧪 Testing Instructions

### Test 1: Manual Notification (Firebase Console)

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Enter your FCM token (check app logs for token)
6. Click "Test"

### Test 2: Low Soil Moisture Alert

1. Create a sensor with type `soil_moisture`
2. Add a reading with value below 30:
   ```dart
   await FirebaseFirestore.instance.collection('sensor_readings').add({
     'sensorId': 'your_sensor_id',
     'value': 20.0,  // Below threshold
     'timestamp': Timestamp.now(),
   });
   ```
3. Wait for the next scheduled check (or trigger manually)
4. You should receive notification: "💧 Irrigation Needed"

### Test 3: Low Water Level Alert

1. Create a sensor with type `water_level`
2. Add a reading with value below 20:
   ```dart
   await FirebaseFirestore.instance.collection('sensor_readings').add({
     'sensorId': 'your_sensor_id',
     'value': 15.0,  // Below low threshold
     'timestamp': Timestamp.now(),
   });
   ```
3. Wait for the next scheduled check
4. You should receive notification: "⚠️ Low Water Level"

### Test 4: Schedule Reminder

1. Create an irrigation schedule for 30 minutes from now:
   ```dart
   await FirebaseFirestore.instance.collection('irrigation_schedules').add({
     'userId': 'your_user_id',
     'fieldId': 'your_field_id',
     'status': 'active',
     'scheduledTime': Timestamp.fromDate(DateTime.now().add(Duration(minutes: 30))),
   });
   ```
2. Wait for the next check
3. You should receive notification: "⏰ Irrigation Reminder"

### Test 5: Irrigation Status Change

1. Create or update an irrigation cycle:
   ```dart
   await FirebaseFirestore.instance.collection('irrigation_cycles').doc('cycle_id').update({
     'status': 'running',
   });
   ```
2. You should receive notification: "💧 Irrigation Started"

### Test 6: Background Notifications

1. Close the app completely
2. Trigger any of the above tests
3. You should still receive notifications
4. Tap notification to open app

---

## 🔍 Debugging

### Check FCM Token

Look for this in app logs when you log in:
```
✓ FCM Token: [your_token_here]
```

### Check Cloud Function Logs

```bash
firebase functions:log
```

Or view in Firebase Console → Functions → Logs

### Common Issues

#### Notifications Not Received
1. Check if FCM token is saved in user document
2. Verify Cloud Functions are deployed
3. Check function logs for errors
4. Ensure sensor data exists in Firestore

#### Background Notifications Not Working
1. Android: Check battery optimization settings
2. iOS: Ensure app has notification permissions
3. Verify background message handler is registered

#### Token Not Saved
1. Check if user is logged in when FCM initializes
2. Verify Firestore permissions
3. Check for errors in logs

---

## 📱 Notification Types & Navigation

| Type | Title | When Triggered | Navigation Target |
|------|-------|----------------|-------------------|
| `irrigation_needed` | 💧 Irrigation Needed | Moisture < 30% | Field Details |
| `water_low` | ⚠️ Low Water Level | Water < 20% | Sensor Details |
| `water_low` (critical) | 🚨 Critical: Water Level | Water < 10% | Sensor Details |
| `schedule_reminder` | ⏰ Irrigation Reminder | 30 min before schedule | Schedule Details |
| `irrigation_status` | Various | Status changes | Irrigation Details |

---

## 🎯 Customization Options

### Adjust Alert Frequencies

Edit in `functions/index.js`:

```javascript
// Change from "every 2 hours" to "every 1 hours"
exports.checkIrrigationNeeds = functions.pubsub
  .schedule('every 1 hours')  // ← Change here
  .onRun(async (context) => {
    // ...
  });
```

### Adjust Thresholds

Thresholds are stored in sensor documents:
```javascript
{
  lowThreshold: 30,        // For soil moisture
  criticalThreshold: 10,   // For water level
}
```

### Adjust Cooldown Periods

In `functions/index.js`, change:
```javascript
// Irrigation alerts: 6-hour cooldown
if (hoursSinceLastAlert < 6) {  // ← Change here
  shouldAlert = false;
}

// Water level alerts: 4-hour cooldown
if (hoursSinceLastAlert < 4) {  // ← Change here
  shouldAlert = false;
}
```

---

## 🔐 Security Notes

1. **Token Privacy**: FCM tokens are stored securely in Firestore
2. **User-Specific**: All notifications are sent only to the specific user
3. **Invalid Tokens**: Automatically removed to prevent errors
4. **Firestore Rules**: Ensure proper security rules are in place

---

## 📦 Dependencies Added

Already included in your `pubspec.yaml`:
- `firebase_messaging: ^14.7.0` ✅
- `flutter_local_notifications: ^17.0.0` ✅

---

## ✨ Features

### What Works Now:
- ✅ Notifications work even when app is closed
- ✅ Automatic soil moisture monitoring
- ✅ Automatic water level monitoring
- ✅ Schedule reminders
- ✅ Real-time irrigation status updates
- ✅ Multiple device support (one user can get notifications on multiple devices)
- ✅ Automatic token management
- ✅ Duplicate alert prevention

### Notification Behavior:
- **App in Foreground**: Shows local notification + adds to message stream
- **App in Background**: Shows system notification
- **App Closed**: Shows system notification (via background handler)
- **Tap Notification**: Opens app and navigates to relevant screen

---

## 🚀 Next Steps

1. **Deploy Functions**: `firebase deploy --only functions`
2. **Test Notifications**: Follow testing instructions above
3. **Monitor Logs**: Check Firebase Console for function execution
4. **Create Test Data**: Add sensors and readings to test alerts
5. **Customize**: Adjust thresholds and frequencies as needed

---

## 📞 Support

If you encounter issues:
1. Check function logs: `firebase functions:log`
2. Verify FCM token in Firestore user document
3. Ensure sensor data exists
4. Check Firebase Console for API enablement

---

**Implementation Status**: ✅ COMPLETE & READY TO DEPLOY

All FCM functionality is implemented and ready for testing!
