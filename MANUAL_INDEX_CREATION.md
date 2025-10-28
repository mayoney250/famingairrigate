# 📝 Create Firestore Indexes Manually

## Step-by-Step Guide

### STEP 1: Navigate to Indexes

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project: **ngairrigate**
3. Click **Firestore Database** in left sidebar
4. Click the **Indexes** tab at the top
5. Click **"+ Create Index"** button

---

### INDEX 1: Irrigation Schedules

**Click "+ Create Index" and enter:**

| Setting | Value |
|---------|-------|
| **Collection ID** | `irrigationSchedules` |
| **Query scope** | Collection |

**Add these fields IN ORDER:**

1. **Field 1:**
   - Field path: `userId`
   - Order: **Ascending**

2. **Field 2:**
   - Field path: `isActive`
   - Order: **Ascending**

3. **Field 3:**
   - Field path: `nextRun`
   - Order: **Ascending**

**Click "Create"**

Wait for status to change from "Building" to "Enabled" (1-5 minutes)

---

### INDEX 2: Weather Data

**Click "+ Create Index" again and enter:**

| Setting | Value |
|---------|-------|
| **Collection ID** | `weatherData` |
| **Query scope** | Collection |

**Add these fields IN ORDER:**

1. **Field 1:**
   - Field path: `userId`
   - Order: **Ascending**

2. **Field 2:**
   - Field path: `timestamp`
   - Order: **Ascending**

**Click "Create"**

Wait for status to change to "Enabled"

---

## Visual Guide

### What It Should Look Like:

```
Firebase Console
└─ Firestore Database
   └─ Indexes Tab
      ├─ Index 1: irrigationSchedules
      │  ├─ userId (Ascending)
      │  ├─ isActive (Ascending)
      │  └─ nextRun (Ascending)
      │  Status: [Building...] → [Enabled] ✓
      │
      └─ Index 2: weatherData
         ├─ userId (Ascending)
         └─ timestamp (Ascending)
         Status: [Building...] → [Enabled] ✓
```

---

## Screenshots Guide

### Creating Index Screen:

You'll see a form like this:
```
┌─────────────────────────────────────┐
│ Create a new composite index        │
├─────────────────────────────────────┤
│ Collection ID:                      │
│ [irrigationSchedules            ]   │
│                                     │
│ Query scope:                        │
│ ○ Collection group                  │
│ ● Collection                        │
│                                     │
│ Fields to index:                    │
│ ┌─────────────────────────────┐   │
│ │ Field path: userId           │   │
│ │ Order: [Ascending ▼]        │   │
│ │ [+ Add another field]        │   │
│ └─────────────────────────────┘   │
│                                     │
│ [Cancel]  [Create]                 │
└─────────────────────────────────────┘
```

---

## Important Notes

⚠️ **Order Matters!** Add fields in the exact order shown above

⚠️ **Collection ID Spelling** Must be exactly:
- `irrigationSchedules` (note the capital S)
- `weatherData` (note the capital D)

⚠️ **Wait for "Enabled"** Don't proceed until both show "Enabled" status

---

## After Creating Indexes

### STEP 2: Create Test Data

Now that indexes are creating, let's add test irrigation data:

1. Go to **Firestore Database → Data tab**
2. Find the **`users`** collection
3. Click on YOUR user document
4. **Copy the Document ID** (this is your userId)

Now create test irrigation:

1. Click **"Start collection"** (or navigate to existing `irrigationSchedules`)
2. **Collection ID:** `irrigationSchedules`
3. **Add Document** with these fields:

```
userId: [YOUR_USER_ID_FROM_STEP_ABOVE]
name: "Test Running Irrigation"
zoneId: "test_field_1"
zoneName: "Test Field 1"
startTime: [Click timestamp icon, select TODAY + current time]
durationMinutes: 30
repeatDays: []
isActive: true
status: "running"          ← MUST BE "running" for stop button
createdAt: [Click timestamp, select now]
lastRun: null
nextRun: null
stoppedAt: null
stoppedBy: null
```

**Field Types:**
- Strings: userId, name, zoneId, zoneName, status
- Number: durationMinutes
- Boolean: isActive
- Array: repeatDays (empty)
- Timestamp: startTime, createdAt
- Null: lastRun, nextRun, stoppedAt, stoppedBy

---

## Verification

### Check Indexes Status:
1. Firestore → Indexes tab
2. Both should show "Enabled" ✓

### Check Test Data:
1. Firestore → Data tab
2. Open `irrigationSchedules` collection
3. You should see your test document
4. `status` field should be "running"

---

## Test in App

1. **Wait for both indexes to be "Enabled"**
2. **Hot restart app**: Press 'R' in terminal
3. **Navigate to Irrigation screen** (water drop icon)
4. **You should see:**
   - Test Running Irrigation card
   - Green "RUNNING" badge
   - Red "STOP IRRIGATION" button
5. **Tap Stop → Confirm → Watch it change to STOPPED**

---

## Troubleshooting

### Can't Find Indexes Tab
- Make sure you're in Firestore Database (not Realtime Database)
- Tab is at the top: Data | Rules | Indexes | Usage

### "Create Index" Button Disabled
- Wait a moment, page might still be loading
- Refresh the browser
- Make sure you have Owner/Editor permissions

### Index Stuck on "Building"
- Normal! Can take 1-10 minutes
- Refresh the page to check status
- If > 10 minutes, check Firebase Status page

### Still Getting "requires an index" Error
- Indexes might not be enabled yet
- Check Indexes tab shows "Enabled" not "Building"
- Try hot restart again after they're enabled

---

## Quick Reference

**Index 1:** irrigationSchedules
- userId ↑
- isActive ↑  
- nextRun ↑

**Index 2:** weatherData
- userId ↑
- timestamp ↑

(↑ = Ascending order)

---

## Next Steps After Indexes Are Enabled

1. ✅ Create test irrigation data (see above)
2. ✅ Hot restart app
3. ✅ Test stop feature
4. ✅ Tell me if you see the stop button!

Let me know when indexes show "Enabled" status! 🚀

