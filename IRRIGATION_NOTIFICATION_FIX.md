# 🔧 Irrigation Status Change Notification Fix

## Problem
Notifications were not appearing when irrigation status changed (starting, stopping, completing irrigation cycles).

## Root Causes Identified

### 1. Wrong Collection Name ❌
The notification service was listening to `irrigation_cycles` collection, but your app uses `irrigationSchedules` collection.

**Before:**
```dart
.collection('irrigation_cycles')
```

**After:**
```dart
.collection('irrigationSchedules')
```

### 2. Status Case Sensitivity ❌
The handler only matched exact lowercase status values, but Firestore might store them with different casings.

**Before:**
```dart
switch (status) {
  case 'running':  // Only matched exact lowercase
    ...
}
```

**After:**
```dart
// Normalize status first
final rawStatus = data['status'];
final status = (rawStatus is String ? rawStatus : rawStatus?.toString())
    ?.toLowerCase()
    .trim();

switch (status) {
  case 'running':
  case 'started':  // Handle variations
  case 'active':
    ...
}
```

### 3. Missing Field Name Mapping ❌
The app stores field info in `zoneId` and `zoneName` fields, not `fieldId` and `name`.

**Before:**
```dart
final fieldId = data['fieldId'] as String?;
String fieldName = 'your field';
```

**After:**
```dart
// Check both fieldId and zoneId
final fieldId = data['fieldId'] as String? ?? data['zoneId'] as String?;
String fieldName = data['zoneName'] as String? ?? 
                   data['name'] as String? ?? 
                   'your field';
```

### 4. Missing UserId Fallback ❌
Some irrigation documents might not have `userId`, causing the handler to exit early.

**Before:**
```dart
final userId = data['userId'] as String?;
if (userId == null) {
  return;  // Exit without notification
}
```

**After:**
```dart
// Use current user if not in document
final userId = data['userId'] as String? ?? 
               FirebaseAuth.instance.currentUser?.uid;
```

## Changes Made

### File: `lib/services/notification_service.dart`

1. **Line 402**: Changed collection from `irrigation_cycles` to `irrigationSchedules`

2. **Line 414**: Changed trigger to only `DocumentChangeType.modified` (avoid notifications on creation)

3. **Lines 440-446**: Added status normalization and userId fallback

4. **Lines 458-464**: Added support for `zoneId`/`zoneName` fields

5. **Lines 482-522**: Added status variations for all cases:
   - `running`/`started`/`active`
   - `completed`/`complete`/`finished`
   - `stopped`/`stop`/`cancelled`
   - `failed`/`error`

6. **Line 525**: Added detailed logging for unknown status values

7. **Line 529**: Added log before sending notification

## How It Works Now

### Flow:
1. User starts/stops irrigation → Updates `irrigationSchedules` document
2. Firestore listener detects modification
3. Handler normalizes status and extracts field info
4. Creates alert in Firestore `alerts` collection
5. Shows local notification to user

### Supported Status Changes:
| Status | Notification |
|--------|-------------|
| `running`, `started`, `active` | ▶️ Irrigation Started |
| `completed`, `complete`, `finished` | ✅ Irrigation Completed |
| `stopped`, `stop`, `cancelled` | ⏹️ Irrigation Stopped |
| `failed`, `error` | ❌ Irrigation Failed |

## Testing Instructions

### Step 1: Start Manual Irrigation
1. Open app and go to Dashboard
2. Click "Manual Start" in Quick Actions
3. Select a field and duration
4. Click "Start Now"
5. **Expected**: You should see "▶️ Irrigation Started" notification

### Step 2: Monitor Logs
Watch for these logs in console:
```
[IRRIGATION] Snapshot received - size: X, changes: 1
[IRRIGATION] Change type: modified, docId: ...
[IRRIGATION] Document data: {status: running, ...}
[IRRIGATION] Normalized status: running
[IRRIGATION] Field name: Field A
[IRRIGATION] About to send notification - Title: ▶️ Irrigation Started
[NOTIFICATION] Calling show() with ID: ...
[NOTIFICATION] show() completed successfully
```

### Step 3: Check Alert Center
1. Tap bell icon in app bar
2. Verify alert appears with irrigation status
3. Mark as read and dismiss

### Step 4: Test Completion
1. Wait for irrigation to complete or stop it manually
2. **Expected**: You should see completion/stopped notification

## Debugging

### If you don't see notifications:

1. **Check logs for listener attachment:**
   ```
   [IRRIGATION] Setting up listener for userId: ...
   [IRRIGATION] Listener attached successfully
   ```

2. **Check if snapshots are received:**
   ```
   [IRRIGATION] Snapshot received - size: X
   ```
   - If size is 0, no documents match the query
   - Check that `irrigationSchedules` has `userId` field

3. **Check status normalization:**
   ```
   [IRRIGATION] Normalized status: running
   ```
   - If you see "Unknown status value", add that variation to the switch

4. **Check notification permissions:**
   - Go to Profile → Notification Test
   - Click "Send Test Notification"
   - If test works but irrigation doesn't, it's a listener/data issue

5. **Verify document structure:**
   ```dart
   // Expected irrigationSchedules document:
   {
     'userId': 'user123',
     'status': 'running',  // or 'completed', 'stopped', 'failed'
     'zoneId': 'field123',
     'zoneName': 'Field A',
     'durationMinutes': 30,
     ...
   }
   ```

## Common Issues & Solutions

### Issue: Notification on creation
**Solution**: We now only trigger on `DocumentChangeType.modified`, not `added`

### Issue: Field name shows as "your field"
**Solution**: Ensure `zoneName` is set in `irrigationSchedules` document, or field exists in `fields` collection

### Issue: Multiple notifications for same event
**Solution**: This is expected if status changes multiple times. Consider adding cooldown logic if needed.

### Issue: No notification when app is closed
**Solution**: Local notifications only work when app is running. For background delivery, ensure FCM is working (see PUSH_NOTIFICATION_FIX.md)

## Status: ✅ FIXED

All irrigation status change notifications should now work correctly!

## Related Documents
- `PUSH_NOTIFICATION_FIX.md` - For FCM/background notifications
- `FCM_SETUP_AND_TESTING.md` - For Cloud Functions setup
- `lib/services/notification_service.dart` - Main notification service
- `lib/services/irrigation_status_service.dart` - Irrigation management
