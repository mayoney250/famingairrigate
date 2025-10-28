# ✅ CREATE TEST DATA - Step by Step

## You Need To Do This in Firebase Console

### STEP 1: Create Firestore Indexes (REQUIRED)

**Click these links - they will auto-create the indexes for you:**

1. **Irrigation Schedule Index:**
   Click this link (from your error message):
   ```
   https://console.firebase.google.com/v1/r/project/ngairrigate/firestore/indexes?create_composite=Cldwcm9qZWN0cy9uZ2FpcnJpZ2F0ZS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvaXJyaWdhdGlvblNjaGVkdWxlcy9pbmRleGVzL18QARoMCghpc0FjdGl2ZRABGgoKBnVzZXJJZBABGgsKB25leHRSdW4QARoMCghfX25hbWVfXxAB
   ```
   - Click **"Create Index"** button
   - Wait 1-2 minutes for it to build (Status shows "Building..." then "Enabled")

2. **Weather Data Index:**
   Click this link (from your error message):
   ```
   https://console.firebase.google.com/v1/r/project/ngairrigate/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9uZ2FpcnJpZ2F0ZS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvd2VhdGhlckRhdGEvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAEaDAoIX19uYW1lX18QAQ
   ```
   - Click **"Create Index"** button
   - Wait 1-2 minutes for it to build

**Wait for both indexes to show "Enabled" status before continuing!**

---

### STEP 2: Get Your User ID

1. Go to Firebase Console → Firestore Database
2. Click on `users` collection
3. Click on your user document
4. **Copy the Document ID** (this is your userId)
   - It looks like: `abc123xyz456...`
   - **Keep this - you'll need it!**

---

### STEP 3: Create Test Irrigation Schedule (To Test Stop Feature)

1. **In Firestore Console**, click **"Start Collection"** button
2. **Collection ID:** `irrigationSchedules`
3. **Document ID:** Leave as "Auto-ID"
4. **Add these fields exactly as shown:**

| Field Name | Field Type | Value |
|------------|-----------|-------|
| `userId` | string | **[YOUR_USER_ID from Step 2]** |
| `name` | string | `Test Running Irrigation` |
| `zoneId` | string | `test_field_1` |
| `zoneName` | string | `Test Field 1` |
| `startTime` | timestamp | **Click calendar, select today, time: now** |
| `durationMinutes` | number | `30` |
| `repeatDays` | array | Leave empty `[]` |
| `isActive` | boolean | `true` |
| `status` | string | `running` |
| `createdAt` | timestamp | **Click calendar, select today, time: now** |
| `lastRun` | timestamp | **Leave as null** |
| `nextRun` | timestamp | **Leave as null** |
| `stoppedAt` | timestamp | **Leave as null** |
| `stoppedBy` | string | **Leave as null** |

**CRITICAL:** 
- Make sure `status` = `running` (not "scheduled")
- Make sure `userId` matches YOUR user ID
- Timestamps must be type "timestamp", not string

5. Click **Save**

---

### STEP 4: Create Another Test Schedule (For Dashboard)

1. **Add Document** (in same collection)
2. **Use same fields as above BUT:**
   - `name`: `Scheduled Irrigation`
   - `status`: `scheduled` (not "running")
   - `startTime`: **Tomorrow at 10:00 AM**
   - `nextRun`: **Same as startTime (tomorrow 10 AM)**

---

### STEP 5: Test the Stop Feature

1. **Wait for indexes to finish building** (check Firebase Console → Firestore → Indexes tab)
2. **Hot restart your app** (press 'R' in terminal)
3. **Navigate to Irrigation screen** (water drop icon in bottom nav)
4. **You should see:**
   - ✅ Test Running Irrigation with **green "RUNNING" badge**
   - ✅ **Red "Stop Irrigation" button** at the bottom
5. **Tap "Stop Irrigation"**
6. **Confirm in dialog**
7. **Watch it change to:**
   - ✅ Orange "STOPPED" badge
   - ✅ Button disappears

---

## Verification Checklist

After creating the data:

### ✅ Dashboard Should Show:
- Next scheduled irrigation (the one scheduled for tomorrow)
- Weather data
- Soil moisture
- Weekly stats

### ✅ Irrigation Screen Should Show:
- Two irrigation schedules:
  1. Test Running Irrigation (with STOP button)
  2. Scheduled Irrigation (no stop button, just scheduled)

---

## If Indexes Take Too Long

Firestore composite indexes can take 1-10 minutes to build. While waiting:

**Alternative: Use the Auto-Generated Links**

The error messages gave you direct links. Just click them:
1. First link creates irrigation schedule index
2. Second link creates weather data index
3. Wait for "Enabled" status
4. Refresh your app

---

## Quick Copy-Paste for Firestore

**For the RUNNING irrigation (field values):**
```
userId: [YOUR_USER_ID_HERE]
name: Test Running Irrigation
zoneId: test_field_1
zoneName: Test Field 1
startTime: [timestamp - today]
durationMinutes: 30
repeatDays: []
isActive: true
status: running
createdAt: [timestamp - today]
lastRun: null
nextRun: null
stoppedAt: null
stoppedBy: null
```

---

## After You Complete These Steps

**Tell me:**
1. ✅ Indexes created and enabled?
2. ✅ Test data created?
3. ✅ Can you see the irrigation schedules in the app?
4. ✅ Can you see the STOP button?
5. ✅ Does the stop button work?

**Then we'll verify everything is working correctly!**

