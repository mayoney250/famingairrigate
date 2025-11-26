# Sensor Data Not Showing - Solution Guide

## Your Data Structure ✅

Your `sensorData` document structure is **CORRECT**:

```json
{
  "battery": 30,
  "fieldId": "Efi0W7TYyMqQvycxedWK",
  "humidity": 30,
  "id": null,
  "soilMoisture": 35,
  "temperature": 80,
  "timestamp": Timestamp,
  "userId": "hYPhcKYXgUhnsRwY2RIcZOoNgpf2"
}
```

## Why It's Not Showing

The app uses a **cache-first strategy**:
1. ✅ Checks local Hive cache first (instant)
2. ✅ Returns cached data if available
3. ✅ Fetches from Firestore in background
4. ✅ Updates cache with fresh data

**Problem**: You just added data manually, so the cache is empty. The app returns empty results immediately, then fetches in the background.

---

## Solution 1: Clear Cache (Recommended)

### Step 1: Open Browser Console
- Press `F12` or `Ctrl+Shift+I`
- Click the "Console" tab

### Step 2: Run this command:
```javascript
indexedDB.deleteDatabase('hive');
```

### Step 3: Reload the page
```javascript
location.reload();
```

### Step 4: Wait 5-10 seconds
The app will fetch from Firestore and populate the cache.

---

## Solution 2: Check for Missing Index

Firestore requires a **composite index** for the query:
- Collection: `sensorData`
- Fields: `fieldId` (Ascending) + `timestamp` (Descending)

### How to check:

1. Run the debug script (see below)
2. If you see error `failed-precondition`, you need to create an index
3. Click the link in the error message to create it automatically
4. Wait 2-3 minutes for index to build
5. Reload the page

---

## Solution 3: Verify Data with Debug Script

### Step 1: Copy the debug script
Open `web/debug_sensor_data.js` and copy all contents

### Step 2: Paste in browser console
Press F12 → Console tab → Paste the script → Press Enter

### Step 3: Check the output
The script will tell you:
- ✅ If Firestore has your data
- ✅ If there's a missing index
- ✅ If the cache exists
- ✅ If you're logged in

---

## Common Issues & Fixes

### Issue 1: Missing Firestore Index
**Error**: `failed-precondition` or `The query requires an index`

**Fix**:
1. Look for a link in the error message
2. Click it to open Firebase Console
3. Click "Create Index"
4. Wait 2-3 minutes
5. Reload your app

### Issue 2: Wrong fieldId
**Symptom**: Query returns 0 results

**Fix**:
1. Check your selected field in the app
2. Verify the `fieldId` in your Firestore document matches exactly
3. Field IDs are case-sensitive!

### Issue 3: Security Rules Blocking Read
**Error**: `permission-denied`

**Fix**: Update Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /sensorData/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Issue 4: Cache Not Updating
**Symptom**: Old data keeps showing

**Fix**:
```javascript
// Clear cache
indexedDB.deleteDatabase('hive');

// Force reload (bypass cache)
location.reload(true);
```

---

## Quick Checklist

- [ ] Collection name is `sensorData` (exact case)
- [ ] Document has `fieldId` field
- [ ] `fieldId` matches your selected field in the app
- [ ] Document has `timestamp` field (Firestore Timestamp type)
- [ ] You're logged in (check console: `firebase.auth().currentUser`)
- [ ] Firestore index exists (check Firebase Console)
- [ ] Security rules allow reading
- [ ] Cache is cleared

---

## Still Not Working?

Run this in console and share the output:

```javascript
// Get your current field ID
const fieldId = 'Efi0W7TYyMqQvycxedWK'; // Replace with your actual field ID

// Check Firestore
firebase.firestore()
  .collection('sensorData')
  .where('fieldId', '==', fieldId)
  .limit(1)
  .get()
  .then(snap => {
    console.log('Found docs:', snap.docs.length);
    if (snap.docs.length > 0) {
      console.log('Sample doc:', snap.docs[0].data());
    }
  })
  .catch(err => console.error('Error:', err));
```

Share:
1. The console output
2. Screenshot of your Firestore document
3. Any error messages
