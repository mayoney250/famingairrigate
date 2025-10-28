# 🗄️ Setup Firestore Database from Scratch

## Your Firestore is Empty - Let's Fix That!

Since you have NO collections, we'll create everything step by step.

---

## STEP 1: Create Users Collection First

### 1.1 Get Your Authentication UID
You're logged into the app, so you have a Firebase Auth UID. Let's find it:

**Option A: From Firebase Console**
1. Go to Firebase Console
2. Click **Authentication** (left sidebar)
3. Click **Users** tab
4. You should see your email
5. **Copy the User UID** (long string like: `abc123xyz456...`)

**Option B: From App (if you can access profile)**
- If your profile screen shows any ID, use that

**Your UID:** `________________________` (write it down!)

---

## STEP 2: Create Collections Manually

Now we'll create the essential collections:

### 2.1 Create Users Collection

1. In Firestore Console, click **"+ Start collection"**
2. **Collection ID:** `users`
3. **Document ID:** **[Use your UID from Step 1]**
4. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `userId` | string | **[Same as document ID]** |
| `email` | string | **[Your email]** |
| `firstName` | string | `Test` |
| `lastName` | string | `User` |
| `phoneNumber` | string | `+250700000000` |
| `isActive` | boolean | `true` |
| `isVerified` | boolean | `true` |
| `createdAt` | timestamp | **Click calendar, select NOW** |
| `role` | string | `farmer` |

Click **Save**

---

### 2.2 Create Irrigation Schedules Collection

1. Click **"+ Start collection"** again
2. **Collection ID:** `irrigationSchedules`
3. **Document ID:** Auto-ID (leave it)
4. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `userId` | string | **[YOUR UID from Step 1]** |
| `name` | string | `Test Running Irrigation` |
| `zoneId` | string | `test_field_1` |
| `zoneName` | string | `Test Field 1` |
| `startTime` | timestamp | **NOW** |
| `durationMinutes` | number | `30` |
| `repeatDays` | array | `[]` (empty) |
| `isActive` | boolean | `true` |
| `status` | string | `running` |
| `createdAt` | timestamp | **NOW** |
| `lastRun` | null | - |
| `nextRun` | null | - |
| `stoppedAt` | null | - |
| `stoppedBy` | null | - |

Click **Save**

---

### 2.3 Create Weather Data Collection (Optional)

1. **Collection ID:** `weatherData`
2. **Document ID:** Auto-ID
3. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `userId` | string | **[YOUR UID]** |
| `temperature` | number | `26` |
| `humidity` | number | `65` |
| `condition` | string | `Sunny` |
| `description` | string | `Clear sky` |
| `location` | string | `Kigali` |
| `timestamp` | timestamp | **NOW** |

Click **Save**

---

## STEP 3: Create the Indexes

Now create indexes as we discussed:

### INDEX 1: irrigationSchedules
1. Firestore → **Indexes** tab
2. Click **"+ Create Index"**
3. Collection: `irrigationSchedules`
4. Add fields:
   - `userId` (Ascending)
   - `isActive` (Ascending)
   - `nextRun` (Ascending)
5. Click **Create**

### INDEX 2: weatherData
1. Click **"+ Create Index"** again
2. Collection: `weatherData`
3. Add fields:
   - `userId` (Ascending)
   - `timestamp` (Ascending)
4. Click **Create**

**Wait for both to show "Enabled" status**

---

## STEP 4: Verify Your Database

After creating everything, your Firestore should look like:

```
Firestore Database
├─ users
│  └─ [your-uid]
│     ├─ userId: "your-uid"
│     ├─ email: "your@email.com"
│     ├─ firstName: "Test"
│     └─ ...
│
├─ irrigationSchedules
│  └─ [auto-id]
│     ├─ userId: "your-uid"
│     ├─ name: "Test Running Irrigation"
│     ├─ status: "running"
│     └─ ...
│
└─ weatherData (optional)
   └─ [auto-id]
      ├─ userId: "your-uid"
      ├─ temperature: 26
      └─ ...
```

---

## STEP 5: Test in App

1. **Wait for indexes to be "Enabled"**
2. **Hot restart app:** Press 'R' in terminal
3. **Navigate to Irrigation screen**
4. **You should now see:**
   - ✅ Your test irrigation schedule
   - ✅ Green "RUNNING" badge
   - ✅ **RED "STOP IRRIGATION" BUTTON**

5. **Test the stop feature:**
   - Tap "Stop Irrigation"
   - Confirm in dialog
   - Watch status change to "STOPPED"

6. **Verify in Firestore:**
   - Open your irrigation document
   - Check `status` changed to "stopped"
   - Check `stoppedAt` has a timestamp
   - Check `stoppedBy` says "manual"

---

## Why Was Your Database Empty?

This happens when:
- ✅ Firebase Authentication is working (you can log in)
- ❌ But Firestore write operations aren't happening
- ❌ User registration didn't create Firestore documents

**This is normal for a new setup!** You just need to create the initial data structure.

---

## After This Works

Once the stop feature works with test data, you can:
1. Create more test irrigation schedules
2. Test with different statuses (scheduled, running, stopped, completed)
3. Set up proper user registration to auto-create Firestore documents
4. Add real field data
5. Connect real IoT sensors

---

## Quick Copy-Paste Template

For the **RUNNING irrigation** (easy copy):

```
Collection: irrigationSchedules
Document: Auto-ID

userId: [PASTE_YOUR_UID_HERE]
name: Test Running Irrigation
zoneId: test_field_1
zoneName: Test Field 1
startTime: [timestamp-now]
durationMinutes: 30
repeatDays: []
isActive: true
status: running
createdAt: [timestamp-now]
lastRun: null
nextRun: null
stoppedAt: null
stoppedBy: null
```

---

## Checklist

Before hot restarting:

- [ ] Found your Authentication UID
- [ ] Created `users` collection with your user
- [ ] Created `irrigationSchedules` collection with test data
- [ ] Set `status` field to "running"
- [ ] Created both indexes (irrigationSchedules, weatherData)
- [ ] Both indexes show "Enabled" status
- [ ] Hot restart app (press 'R')

---

## What You'll See After

### ✅ Dashboard:
- Real user name (Test User)
- Real irrigation schedule
- Weather data (if you created it)

### ✅ Irrigation Screen:
- Test Running Irrigation card
- Green RUNNING badge
- **Red STOP IRRIGATION button** ← This is what we want!

### ✅ After Stopping:
- Orange STOPPED badge
- No stop button (already stopped)
- Timestamp in Firestore

---

## Need Help?

Tell me:
1. ✅ Did you find your Authentication UID?
2. ✅ Were you able to create the collections?
3. ✅ Did the indexes get created?
4. ✅ What do you see after hot restart?

Let's get your database set up! 🚀

