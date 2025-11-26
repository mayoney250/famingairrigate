# Firestore Data Not Showing - Troubleshooting Guide

## Problem
You've manually added data to Firestore, but it's not appearing in the app.

## Root Causes & Solutions

### 1. **Collection Name Mismatch** ⚠️

Your app expects **specific collection names** (case-sensitive):

| Feature | Collection Name | ❌ Wrong | ✅ Correct |
|---------|----------------|----------|-----------|
| Irrigation Schedules | `irrigationSchedules` | `irrigation_schedules` | `irrigationSchedules` |
| Sensors | `sensors` | `Sensors` | `sensors` |
| Sensor Readings | `sensor_readings` | `sensorReadings` | `sensor_readings` |

**Action**: Check your Firebase Console and ensure collection names match exactly.

---

### 2. **Missing or Incorrect `userId` Field**

The app filters data by `userId`, which comes from **Firebase Authentication**.

#### How to find your userId:
1. Open browser DevTools (F12)
2. Go to Console tab
3. Run this command:
   ```javascript
   firebase.auth().currentUser.uid
   ```
4. Copy the output (e.g., `"abc123xyz456..."`)

#### Fix your Firestore documents:
- Every document in `irrigationSchedules` **must** have a `userId` field
- The value **must exactly match** your Firebase Auth UID
- Example:
  ```json
  {
    "userId": "abc123xyz456...",  // ← Must match your auth UID
    "name": "Morning Irrigation",
    ...
  }
  ```

---

### 3. **Missing or Incorrect `farmId` Field** (for Sensors)

Sensors are filtered by `farmId` from your selected farm/field.

#### How to find your farmId:
1. Open browser DevTools Console
2. Run:
   ```javascript
   // Check what farmId the app is using
   console.log('Selected Farm ID:', window.localStorage.getItem('selectedFarmId'));
   ```

#### Fix your sensor documents:
```json
{
  "farmId": "YOUR_FARM_ID_HERE",  // ← Must match selected farm
  "displayName": "Soil Sensor 1",
  ...
}
```

---

### 4. **Required Document Structure**

#### Irrigation Schedule Document:
```json
{
  "userId": "YOUR_USER_ID",           // ✅ Required
  "name": "Morning Irrigation",       // ✅ Required
  "zoneId": "field_123",              // ✅ Required
  "zoneName": "North Field",          // ✅ Required
  "startTime": Timestamp,             // ✅ Required (Firestore Timestamp type)
  "durationMinutes": 60,              // ✅ Required (number)
  "repeatDays": [1, 3, 5],            // ✅ Required (array of numbers: 1=Mon, 7=Sun)
  "isActive": true,                   // ✅ Required (boolean)
  "status": "scheduled",              // ✅ Required ("scheduled", "running", "completed")
  "createdAt": Timestamp,             // ✅ Required
  "lastRun": Timestamp,               // Optional
  "nextRun": Timestamp,               // Optional
  "stoppedAt": Timestamp,             // Optional
  "stoppedBy": "user@example.com",    // Optional
  "isManual": false                   // Optional
}
```

#### Sensor Document:
```json
{
  "farmId": "YOUR_FARM_ID",           // ✅ Required
  "displayName": "Soil Sensor 1",     // ✅ Required
  "type": "soil",                     // ✅ Required
  "hardwareId": "SN12345",            // ✅ Required
  "pairing": {                        // ✅ Required (map/object)
    "method": "BLE",
    "meta": {
      "mac": "00:11:22:33:44:55"
    }
  },
  "status": "active",                 // ✅ Required
  "lastSeenAt": Timestamp,            // Optional
  "assignedZoneId": "zone_1",         // Optional
  "installNote": "Installed near pump" // Optional
}
```

---

### 5. **Firestore Security Rules**

Your security rules might be blocking reads. Check Firebase Console → Firestore Database → Rules.

#### Minimum rules for testing:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read their own data
    match /irrigationSchedules/{document} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
    
    match /sensors/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /sensor_readings/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Quick Debugging Steps

### Step 1: Check Browser Console
1. Open your app
2. Press F12 → Console tab
3. Look for errors (red text)
4. Share any errors you see

### Step 2: Run Debug Script
1. Copy the contents of `web/debug_firestore.js`
2. Paste into browser console
3. Check the output

### Step 3: Verify Data in Firebase Console
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to Firestore Database
4. Check:
   - Collection names are correct
   - Documents have required fields
   - `userId` matches your auth UID
   - Timestamps are actual Timestamp types (not strings)

---

## Common Mistakes

❌ **Wrong**: Collection named `irrigation_schedules` (snake_case)  
✅ **Correct**: Collection named `irrigationSchedules` (camelCase)

❌ **Wrong**: `userId: "user123"` (random string)  
✅ **Correct**: `userId: "abc123xyz456..."` (actual Firebase Auth UID)

❌ **Wrong**: `startTime: "2025-11-25T10:00:00"` (string)  
✅ **Correct**: `startTime: Timestamp` (Firestore Timestamp type)

❌ **Wrong**: `repeatDays: "1,2,3"` (string)  
✅ **Correct**: `repeatDays: [1, 2, 3]` (array of numbers)

---

## Next Steps

1. **Check your Firebase Console** and verify collection names
2. **Get your userId** from the console command above
3. **Update your documents** with the correct userId
4. **Refresh the app** and check if data appears
5. **If still not working**, share:
   - Screenshot of your Firestore collection
   - Browser console errors
   - Output from the debug script
