# Test Irrigation Notifications

## The Issue

Your logs show sensor_readings still has permission errors. But irrigation_cycles and alerts are working.

## Test Now

### Step 1: Run the app and look for these logs:

```
[IRRIGATION] Setting up listener for userId: 0xv5rdRsAFg05aQcAxvlyynaFy73
[IRRIGATION] Listener attached successfully
[IRRIGATION] Snapshot received - size: X, changes: Y
```

### Step 2: Add Test Irrigation Cycle in Firestore

Go to Firestore Console → `irrigation_cycles` collection → Add document:

```json
{
  "userId": "0xv5rdRsAFg05aQcAxvlyynaFy73",
  "fieldId": "test_field",
  "status": "running",
  "createdAt": [current timestamp]
}
```

### Step 3: Watch App Logs

You should immediately see:

```
[IRRIGATION] Snapshot received - size: 1, changes: 1
[IRRIGATION] Change type: added, docId: [auto-generated-id]
[IRRIGATION] Document data: {userId: 0xv5rdRsAFg05aQcAxvlyynaFy73, fieldId: test_field, status: running, ...}
[IRRIGATION] Handler called for cycle: [auto-generated-id]
[IRRIGATION] Data: {userId: ..., status: running, ...}
[IRRIGATION] Status extracted: running
[IRRIGATION] Field name: your field
[IRRIGATION] About to send notification - title: Irrigation Started
[NOTIFICATION] Attempting to show: Irrigation Started
[NOTIFICATION] Calling show() with ID: [id], title: Irrigation Started, body: Irrigation has started for your field.
[NOTIFICATION] show() completed successfully
[IRRIGATION] Notification sent
```

### Step 4: Check Your Phone

Pull down notification tray - you should see:
```
Irrigation Started
Irrigation has started for your field.
```

---

## If It Doesn't Work

### Check what logs you DO see:

**If you see:**
```
[IRRIGATION] Listener attached successfully
[IRRIGATION] Snapshot received - size: 0, changes: 0
```
But nothing when you add the document → **Rules not deployed or wrong collection name**

**If you see:**
```
[IRRIGATION] ERROR in stream: permission-denied
```
→ **Rules NOT deployed. Run: `firebase deploy --only firestore:rules`**

**If you see:**
```
[IRRIGATION] Snapshot received - size: 1, changes: 1
[IRRIGATION] Change type: added
```
But no handler logs → **Handler isn't being awaited or is crashing silently**

**If you see:**
```
[IRRIGATION] Handler called...
[IRRIGATION] About to send notification
[NOTIFICATION] show() completed successfully
```
But no notification on phone → **Android blocking at OS level** (check Settings → Apps → Notifications)

---

## Deploy Rules First!

The rules I updated need to be deployed:

```powershell
firebase deploy --only firestore:rules
```

This fixes the collectionGroup permission issue.
