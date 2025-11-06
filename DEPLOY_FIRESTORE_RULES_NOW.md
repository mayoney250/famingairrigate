# URGENT: Deploy Firestore Rules to Fix Auto-Start

## The Problem
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

The automatic status updates are being blocked by Firestore security rules.

## The Solution

### Option 1: Deploy via Firebase Console (FASTEST)

1. **Go to**: https://console.firebase.google.com/project/famingairrigation/firestore/rules

2. **Replace ALL the rules** with this:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // Fields collection - authenticated users can read/write
    match /fields/{fieldId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data));
    }
    
    // Irrigation systems
    match /irrigation/{irrigationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data));
    }
    
    // Sensors
    match /sensors/{sensorId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data));
    }
    
    // Irrigation schedules - FIXED FOR AUTO-START
    match /irrigationSchedules/{scheduleId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      // Allow updates if user owns the schedule OR if it's just a status update
      allow update: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data) ||
         // Allow status updates for automatic transitions
         (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'startedAt', 'completedAt', 'stoppedAt', 'stoppedBy', 'updatedAt', 'isActive'])));
      allow delete: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data));
    }
    
    // Sensor data
    match /sensorData/{dataId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated();
    }
    
    // Irrigation logs
    match /irrigationLogs/{logId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated();
    }
    
    // Alerts
    match /alerts/{alertId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated();
    }
    
    // Connection tests (for diagnostics)
    match /connection_tests/{testId} {
      allow read, write: if isAuthenticated();
    }
    
    // Irrigation zones
    match /irrigationZones/{zoneId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         !('userId' in resource.data));
    }
  }
}
```

3. **Click "Publish"**

4. **Wait 10 seconds** for the timer to run again

5. **Check your app** - the schedule should auto-start!

### Option 2: Deploy via Command Line

```bash
firebase deploy --only firestore:rules
```

## What Changed?

**Line 53-59** now allows status updates even if the user doesn't explicitly own the document, as long as only these fields are being changed:
- `status`
- `startedAt`
- `completedAt`
- `stoppedAt`
- `stoppedBy`
- `updatedAt`
- `isActive`

This allows the automatic timer to update the status without permission denied errors.

## After Deploying

Within 10 seconds, you should see in the console:
```
🔄 Running status check timer...
🔍 Checking for due schedules at: 2025-11-06 14:50:00
📋 Found 1 scheduled cycles
✅ Auto-starting schedule GUj6SIcT6W8wzag8Linp for west field. Due at: 2025-11-05 14:30:00
✅ Timer check complete: 1 started, 0 completed
```

And your schedule status will change to "RUNNING"! 🎉
